import '../state/turn_state.dart';

/// Reasons why a player is granted a bonus dice roll.
enum BonusRollReason {
  none,
  rolledSix,
  capturedOpponent,
  reachedHome,
}

/// Turn order, bonus-roll chaining, and no-legal-move handling matching Ludo King tactics.
///
/// Tactical chaining rules:
/// 1. Rolling a 6 grants a bonus roll.
/// 2. Capturing (killing) an opponent token grants a bonus roll AND resets consecutive sixes.
/// 3. Reaching final home (progress 57) grants a bonus roll AND resets consecutive sixes.
/// 4. If no bonus roll is earned, the turn advances to the next active seat.
class TurnRules {
  static const int sixForfeitThreshold = 3;
  static const int seatCount = 4;

  const TurnRules();

  /// Called after a dice roll of [diceValue].
  TurnState afterRoll(
    TurnState current, {
    required int diceValue,
    required bool hasLegalMove,
    required List<bool> activeSeats,
  }) {
    final sixesSoFar = diceValue == 6
        ? current.consecutiveSixes + 1
        : current.consecutiveSixes;

    final forfeited = diceValue == 6 && sixesSoFar >= sixForfeitThreshold;

    if (!hasLegalMove || forfeited) {
      return _advanceToNextSeat(current, activeSeats);
    }

    return current.copyWith(
      phase: TurnPhase.awaitingMove,
      consecutiveSixes: sixesSoFar,
    );
  }

  /// Called after a move is completed.
  ///
  /// If [bonusRollReason] is [BonusRollReason.capturedOpponent] or [BonusRollReason.reachedHome],
  /// the player is granted a bonus roll and [consecutiveSixes] resets to 0.
  /// If [bonusRollReason] is [BonusRollReason.rolledSix], the player is granted a bonus roll.
  /// If [bonusRollReason] is [BonusRollReason.none], the turn advances to the next active seat.
  TurnState afterMove(
    TurnState current, {
    required BonusRollReason bonusRollReason,
    required List<bool> activeSeats,
  }) {
    switch (bonusRollReason) {
      case BonusRollReason.capturedOpponent:
      case BonusRollReason.reachedHome:
        // Tactical bonus roll: resets 6-chain counter so player can continue chaining fresh moves!
        return current.copyWith(
          phase: TurnPhase.awaitingRoll,
          consecutiveSixes: 0,
        );
      case BonusRollReason.rolledSix:
        return current.copyWith(
          phase: TurnPhase.awaitingRoll,
        );
      case BonusRollReason.none:
        return _advanceToNextSeat(current, activeSeats);
    }
  }

  /// The next active seat after [current.currentSeat], wrapping around.
  TurnState _advanceToNextSeat(TurnState current, List<bool> activeSeats) {
    var next = (current.currentSeat + 1) % seatCount;
    while (!activeSeats[next]) {
      next = (next + 1) % seatCount;
    }
    return TurnState(
      currentSeat: next,
      phase: TurnPhase.awaitingRoll,
      consecutiveSixes: 0,
    );
  }
}
