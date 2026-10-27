import 'dart:async';

import '../board/board_config.dart';
import '../dice/dice_engine.dart';
import '../rules/capture_rules.dart';
import '../rules/rule_set.dart';
import '../rules/turn_rules.dart';
import '../state/player_state.dart';
import '../state/token_state.dart';
import '../state/turn_state.dart';
import 'game_event.dart';
import 'game_state.dart';

/// The game engine: the central authority validating actions and mutating state.
///
/// Implements production Ludo King mechanics:
/// - Cryptographically secure dice with 3-consecutive-sixes cap (guaranteed 1..5 on 3rd roll).
/// - Tactical bonus roll chaining with reset on capture or pawn finish.
/// - Mode-specific home corridor access and win detection (Classic vs Quick).
/// - Multi-token blocking and safe-star immunity.
class GameEngine {
  GameState _state;
  final RuleSet _rules;
  final DiceEngine _dice;
  final StreamController<GameEvent> _events = StreamController.broadcast();

  GameEngine(GameState initialState, RuleSet rules, DiceEngine dice)
    : _state = initialState,
      _rules = rules,
      _dice = dice;

  GameState get state => _state;
  RuleSet get rules => _rules;

  /// Token IDs belonging to the current player that can legally move with
  /// the most recent dice roll, or an empty list if it isn't currently
  /// time to move.
  List<int> legalMovesForCurrentPlayer() {
    if (_state.turn.phase != TurnPhase.awaitingMove ||
        _state.dice.lastValue == null) {
      return const [];
    }
    final player = _state.playerAt(_state.turn.currentSeat);
    return _rules.movement.legalTokenIds(
      player,
      _state.dice.lastValue!,
      killRequiredToEnterHome: _rules.killRequiredToEnterHome,
    );
  }

  /// Stream of every event emitted by this engine.
  Stream<GameEvent> get events => _events.stream;

  void dispose() => _events.close();

  GameEvent _emit(GameEvent event) {
    _events.add(event);
    return event;
  }

  /// Rolls the dice for the current player.
  ///
  /// If the player has already rolled 2 consecutive sixes in this turn,
  /// the dice roll is constrained to `1..5` (Ludo King parity: no 3rd six).
  GameEvent rollDice() {
    if (_state.status == GameStatus.won) {
      return _emit(const ActionRejected('Game already has a winner.'));
    }
    if (_state.turn.phase != TurnPhase.awaitingRoll) {
      return _emit(const ActionRejected('Not awaiting a roll right now.'));
    }

    // Never roll a 3rd consecutive six in a single turn chain
    final allowSix = _state.turn.consecutiveSixes < 2;
    final value = _dice.roll(allowSix: allowSix);
    final primary = _emit(DiceRolled(value));

    final currentPlayer = _state.playerAt(_state.turn.currentSeat);
    final legalTokenIds = _rules.movement.legalTokenIds(
      currentPlayer,
      value,
      killRequiredToEnterHome: _rules.killRequiredToEnterHome,
    );
    final hasLegalMove = legalTokenIds.isNotEmpty;

    final nextTurn = _rules.turn.afterRoll(
      _state.turn,
      diceValue: value,
      hasLegalMove: hasLegalMove,
      activeSeats: _activeSeats(),
    );

    _state = _state.copyWith(
      dice: _state.dice.copyWith(
        lastValue: value,
        rollsThisTurn: _state.dice.rollsThisTurn + 1,
        awaitingMove: hasLegalMove && nextTurn.phase == TurnPhase.awaitingMove,
      ),
      turn: nextTurn,
    );

    if (!hasLegalMove) {
      _emit(const NoValidMoves());
      _emit(TurnEnded(nextTurn.currentSeat));
      _state = _state.copyWith(dice: _state.dice.nextTurn());
    }

    return primary;
  }

  /// Moves [tokenId] belonging to the current player.
  GameEvent moveToken(int tokenId) {
    if (_state.status == GameStatus.won) {
      return _emit(const ActionRejected('Game already has a winner.'));
    }
    if (_state.turn.phase != TurnPhase.awaitingMove ||
        _state.dice.lastValue == null) {
      return _emit(const ActionRejected('Not awaiting a move right now.'));
    }

    final seat = _state.turn.currentSeat;
    final diceValue = _state.dice.lastValue!;
    final player = _state.playerAt(seat);
    TokenState? token;
    for (final t in player.tokens) {
      if (t.tokenId == tokenId) {
        token = t;
        break;
      }
    }

    if (token == null) {
      return _emit(ActionRejected('Token $tokenId not found for seat $seat.'));
    }
    if (!_rules.movement.canMove(
      token,
      diceValue,
      player: player,
      killRequiredToEnterHome: _rules.killRequiredToEnterHome,
    )) {
      return _emit(ActionRejected('Token $tokenId cannot move by $diceValue.'));
    }

    final wasInBase = token.isInBase;
    final fromProgress = wasInBase ? null : (token.position as OnPath).progress;
    final toProgress = _rules.movement.resultingProgress(token, diceValue);
    final destinationCell = _state.board.pathForSeat(seat).cellAt(toProgress);

    if (_rules.capture.isBlocked(
      cell: destinationCell,
      movingSeat: seat,
      players: _state.players,
    )) {
      return _emit(
        ActionRejected('Destination is blocked by a stacked opponent pair.'),
      );
    }

    var players = _updateToken(
      _state.players,
      seat: seat,
      tokenId: tokenId,
      newPosition: OnPath(toProgress),
    );

    final primary = _emit(
      wasInBase
          ? TokenLeftBase(seat: seat, tokenId: tokenId)
          : TokenMoved(
              seat: seat,
              tokenId: tokenId,
              fromProgress: fromProgress!,
              toProgress: toProgress,
            ),
    );

    final reachedHome = toProgress == BoardConfig.finishProgress;
    if (reachedHome) {
      _emit(TokenFinished(seat: seat, tokenId: tokenId));
    }

    final outcome = _rules.capture.resolve(
      cell: destinationCell,
      movingSeat: seat,
      players: players,
    );

    var hasCaptured = false;
    if (outcome is Captured) {
      hasCaptured = true;
      // Send captured token back to base
      players = _updateToken(
        players,
        seat: outcome.capturedToken.ownerSeat,
        tokenId: outcome.capturedToken.tokenId,
        newPosition: const InBase(),
      );

      // Increment attacker's kill count
      players = [
        for (final p in players)
          if (p.seat == seat) p.copyWith(kills: p.kills + 1) else p,
      ];

      _emit(
        TokenCaptured(
          capturedToken: outcome.capturedToken,
          byTokenId: tokenId,
          bySeat: seat,
        ),
      );
    }

    _state = _state.copyWith(players: players);

    // Check for match winner
    final winnerSeat = _rules.win.checkWinner(players);
    if (winnerSeat != null) {
      _emit(PlayerFinished(winnerSeat));
      _emit(GameWon(winnerSeat));
      _state = _state.copyWith(
        status: GameStatus.won,
        winnerSeat: winnerSeat,
      );
      return primary;
    }

    // Determine bonus roll reason
    final BonusRollReason bonusReason;
    if (reachedHome) {
      bonusReason = BonusRollReason.reachedHome;
    } else if (hasCaptured) {
      bonusReason = BonusRollReason.capturedOpponent;
    } else if (diceValue == 6) {
      bonusReason = BonusRollReason.rolledSix;
    } else {
      bonusReason = BonusRollReason.none;
    }

    final nextTurn = _rules.turn.afterMove(
      _state.turn,
      bonusRollReason: bonusReason,
      activeSeats: _activeSeats(),
    );

    final bool isBonusRoll = nextTurn.currentSeat == seat &&
        nextTurn.phase == TurnPhase.awaitingRoll;

    _state = _state.copyWith(
      turn: nextTurn,
      dice: isBonusRoll
          ? _state.dice.copyWith(awaitingMove: false)
          : _state.dice.nextTurn(),
    );

    if (isBonusRoll) {
      _emit(ExtraTurnGranted(seat, reason: bonusReason));
    } else {
      _emit(TurnEnded(nextTurn.currentSeat));
    }

    return primary;
  }

  List<bool> _activeSeats() {
    final seats = List.filled(4, false);
    for (final player in _state.players) {
      seats[player.seat] = player.isActive;
    }
    return seats;
  }

  List<PlayerState> _updateToken(
    List<PlayerState> players, {
    required int seat,
    required int tokenId,
    required TokenPosition newPosition,
  }) {
    return [
      for (final player in players)
        if (player.seat != seat)
          player
        else
          player.copyWith(
            tokens: [
              for (final token in player.tokens)
                if (token.tokenId != tokenId)
                  token
                else
                  token.copyWith(position: newPosition),
            ],
          ),
    ];
  }
}
