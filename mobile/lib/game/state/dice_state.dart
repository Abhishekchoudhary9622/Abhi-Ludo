/// Immutable snapshot of the dice-related turn state.
///
/// Per docs/game-engine.md, this is deliberately small and dumb: it just
/// records the last rolled value, how many times the current player has
/// rolled this turn, and whether a move is currently owed. Turn-level
/// meaning (does a 6 grant an extra roll? does no-valid-move end the turn?)
/// belongs to `TurnRules`, added in Phase 3 — this class has no rule logic
/// at all.
class DiceState {
  /// The most recent roll's value (1..6), or `null` if no roll has
  /// happened yet this game/turn.
  final int? lastValue;

  /// How many times the current player has rolled during their current
  /// turn (reset to 0 when a turn ends).
  final int rollsThisTurn;

  /// Whether a move is currently owed as a result of [lastValue] (i.e. the
  /// player has rolled but not yet moved a token).
  final bool awaitingMove;

  const DiceState({
    this.lastValue,
    this.rollsThisTurn = 0,
    this.awaitingMove = false,
  });

  DiceState copyWith({
    int? lastValue,
    int? rollsThisTurn,
    bool? awaitingMove,
  }) {
    return DiceState(
      lastValue: lastValue ?? this.lastValue,
      rollsThisTurn: rollsThisTurn ?? this.rollsThisTurn,
      awaitingMove: awaitingMove ?? this.awaitingMove,
    );
  }

  /// A fresh dice state for the start of a new turn (rolls reset to 0).
  DiceState nextTurn() =>
      const DiceState(lastValue: null, rollsThisTurn: 0, awaitingMove: false);

  @override
  String toString() =>
      'DiceState(last: $lastValue, rolls: $rollsThisTurn, '
      'awaitingMove: $awaitingMove)';
}
