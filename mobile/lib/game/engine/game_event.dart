import '../rules/turn_rules.dart';
import '../state/token_state.dart';

/// One-shot outcomes of a [GameEngine] action.
sealed class GameEvent {
  const GameEvent();
}

class DiceRolled extends GameEvent {
  final int value;
  const DiceRolled(this.value);
}

/// The current player rolled but has no legal move; their turn ends immediately.
class NoValidMoves extends GameEvent {
  const NoValidMoves();
}

class TokenLeftBase extends GameEvent {
  final int seat;
  final int tokenId;
  const TokenLeftBase({required this.seat, required this.tokenId});
}

class TokenMoved extends GameEvent {
  final int seat;
  final int tokenId;
  final int fromProgress;
  final int toProgress;
  const TokenMoved({
    required this.seat,
    required this.tokenId,
    required this.fromProgress,
    required this.toProgress,
  });
}

class TokenFinished extends GameEvent {
  final int seat;
  final int tokenId;
  const TokenFinished({required this.seat, required this.tokenId});
}

class TokenCaptured extends GameEvent {
  final TokenState capturedToken;
  final int byTokenId;
  final int bySeat;
  const TokenCaptured({
    required this.capturedToken,
    required this.byTokenId,
    required this.bySeat,
  });
}

class ExtraTurnGranted extends GameEvent {
  final int seat;
  final BonusRollReason reason;
  const ExtraTurnGranted(this.seat, {this.reason = BonusRollReason.none});
}

class TurnEnded extends GameEvent {
  final int nextSeat;
  const TurnEnded(this.nextSeat);
}

class PlayerFinished extends GameEvent {
  final int seat;
  const PlayerFinished(this.seat);
}

class GameWon extends GameEvent {
  final int seat;
  const GameWon(this.seat);
}

/// An action was rejected outright (wrong phase, invalid token, game
/// already over, blocked destination, etc).
class ActionRejected extends GameEvent {
  final String reason;
  const ActionRejected(this.reason);
}
