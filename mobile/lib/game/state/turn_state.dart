/// What the current player is expected to do next.
enum TurnPhase {
  /// The current player has not yet rolled this turn.
  awaitingRoll,

  /// The current player has rolled and must now pick a token to move (or,
  /// if no legal move exists, the turn ends automatically).
  awaitingMove,
}

/// Immutable snapshot of whose turn it is and what's expected next.
///
/// Per docs/game-engine.md, `consecutiveSixes` exists so `TurnRules` can
/// apply the common house-rule cap of three sixes in a row forfeiting the
/// turn (documented in docs/game-rules.md) — this class just stores the
/// count, it doesn't interpret it.
class TurnState {
  final int currentSeat;
  final TurnPhase phase;
  final int consecutiveSixes;

  const TurnState({
    required this.currentSeat,
    this.phase = TurnPhase.awaitingRoll,
    this.consecutiveSixes = 0,
  });

  TurnState copyWith({
    int? currentSeat,
    TurnPhase? phase,
    int? consecutiveSixes,
  }) {
    return TurnState(
      currentSeat: currentSeat ?? this.currentSeat,
      phase: phase ?? this.phase,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
    );
  }

  @override
  String toString() =>
      'TurnState(seat: $currentSeat, phase: $phase, sixes: $consecutiveSixes)';
}
