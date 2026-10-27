import 'random_source.dart';

/// Produces fair six-sided dice rolls.
///
/// Per docs/dice-system.md: [DiceEngine] only produces the raw value. It
/// has zero knowledge of turn state, whose turn it is, or what a 6 means
/// for game flow — that logic lives entirely in `TurnRules` (added in
/// Phase 3). This keeps "dice result validated/consumed by the game
/// engine" (section 15 of the brief) as a clean separation rather than the
/// dice knowing game rules.
///
/// Fairness: `roll()` takes no arguments describing the player, match
/// history, or anything else — it is structurally incapable of favoring
/// anyone, not just "configured" to be fair (section 16).
class DiceEngine {
  final RandomSource _random;

  const DiceEngine(this._random);

  /// Returns a value in `1..6` (or `1..5` if [allowSix] is false), uniformly distributed.
  int roll({bool allowSix = true}) {
    final max = allowSix ? 6 : 5;
    return _random.nextInt(max) + 1;
  }
}

