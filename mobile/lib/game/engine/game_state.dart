import '../board/board_state.dart';
import '../rules/rule_set.dart';
import '../state/dice_state.dart';
import '../state/player_state.dart';
import '../state/turn_state.dart';

enum GameStatus { inProgress, won }

/// The root, immutable snapshot of a match. Per docs/game-engine.md, this
/// is the single source of truth `GameEngine` reads and produces new copies
/// of — no mutable global state lives anywhere else in the engine.
class GameState {
  final GameMode mode;
  final BoardState board;
  final List<PlayerState> players;
  final DiceState dice;
  final TurnState turn;
  final GameStatus status;
  final int? winnerSeat;

  const GameState({
    required this.mode,
    required this.board,
    required this.players,
    required this.dice,
    required this.turn,
    this.status = GameStatus.inProgress,
    this.winnerSeat,
  });

  PlayerState playerAt(int seat) => players.firstWhere((p) => p.seat == seat);

  GameState copyWith({
    List<PlayerState>? players,
    DiceState? dice,
    TurnState? turn,
    GameStatus? status,
    int? winnerSeat,
  }) {
    return GameState(
      mode: mode,
      board: board,
      players: players ?? this.players,
      dice: dice ?? this.dice,
      turn: turn ?? this.turn,
      status: status ?? this.status,
      winnerSeat: winnerSeat ?? this.winnerSeat,
    );
  }

  @override
  String toString() =>
      'GameState(mode: $mode, turn: $turn, dice: $dice, status: $status, '
      'winner: $winnerSeat)';
}
