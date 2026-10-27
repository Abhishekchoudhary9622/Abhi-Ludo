# Dice System

## Requirements

Fair six-sided dice, uniform 1–6 distribution, no hidden favoritism, no predictable sequence, RNG kept separate from game rules, and — for future online play — the server (never the client) is authoritative. See `docs/research.md` §2 for the sourcing behind the choices below.

## Local/offline design (Phases 1–6)

```dart
abstract class RandomSource {
  int nextInt(int max); // returns [0, max)
}

class SecureRandomSource implements RandomSource {
  final Random _random;
  SecureRandomSource() : _random = Random.secure();
  @override
  int nextInt(int max) => _random.nextInt(max);
}

class DiceEngine {
  final RandomSource _random;
  DiceEngine(this._random);
  int roll() => _random.nextInt(6) + 1; // uniform 1..6
}
```

- `Random.secure()` is Dart's documented cryptographically-secure RNG source (`dart:math`); it is preferred over the plain, seedable `Random()` because it removes any possibility of a predictable/seed-reproducible sequence — even though a *local* single-device pass-and-play game has no remote attacker, using the secure source everywhere establishes one consistent, defensible dice implementation instead of two different RNGs for "offline" vs "online" modes.
- `Random.secure()` throws `UnsupportedError` only if the platform genuinely cannot supply secure entropy — not expected on Android. If it were ever to throw, `SecureRandomSource` will catch it once at construction and fall back to `Random()`, and this fallback will be logged (never silent), so it's visible during manual verification rather than hidden.
- `RandomSource` is an interface specifically so `DiceEngine` never touches `dart:math` directly — this lets a deterministic fake `RandomSource` be substituted during manual debug-screen testing (e.g., to test "what happens on three 6's in a row") without touching production RNG code, without needing a full automated test framework.
- `DiceEngine` only produces the raw value. It has zero knowledge of turn state, whose turn it is, or what a 6 means for game flow — that logic lives entirely in `TurnRules` (see game-engine.md), keeping "dice result validated/consumed by the game engine" (section 15) as a clean separation rather than the dice knowing game rules.

## Fairness

- No mechanism anywhere reads player identity, win/loss history, or payment status before generating a roll. `DiceEngine.roll()` takes no arguments describing the player at all — it is structurally incapable of favoring anyone, not just "configured" to be fair.
- Uniform distribution follows directly from `Random.secure().nextInt(6)`, which Dart's own docs describe as a uniformly distributed pseudo-random (cryptographically sourced) integer generator. No custom weighting/bias logic will be added per section 16's explicit prohibition.
- If informal statistical spot-checking is ever desired (e.g., logging roll frequency over a manual playtest session) it can be done by tallying `DiceEngine.roll()` outputs during play — no dedicated automated statistical test harness will be built, matching the "no unnecessary automated testing infrastructure" instruction.

## Online/server-authoritative design (Phase 9+, documented now per section 15's requirement, not implemented yet)

- The Node.js server generates every online-match roll using Node's built-in `crypto.randomInt(1, 7)` (upper bound exclusive, so this yields 1–6) — a standard library API, no extra dependency.
- The client sends only a `ROLL_DICE` intent with no value attached. The server generates the value, applies it through the same rules logic the room's `GameEngine` uses, and broadcasts the resulting `DiceRolled` event/state delta to all sockets in the room. A client-supplied dice value is never accepted or trusted, per section 29's explicit requirement.
- This will be re-verified against current Node.js `crypto` documentation immediately before Phase 9 implementation (per the "verify before implementing" rule), since this document is written ahead of that phase.
