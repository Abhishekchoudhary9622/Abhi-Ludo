# Game Engine

Pure-Dart engine (`lib/game/engine/`, `lib/game/state/`, `lib/game/rules/`) — no Flutter imports. This document describes the *design*; it will be updated to describe *actual implementation* as each phase lands (per the "docs must describe actual implementation" rule), starting Phase 1–4.

## State model

- **`BoardState`** — the `BoardConfig` (see board-system.md) plus the derived `PlayerPath` for each seat, and the live cell-occupancy index. Effectively immutable/static per match (a `BoardConfig` doesn't change mid-match).
- **`TokenState`** — `{ tokenId, playerId, progress (0..57 or a `base` sentinel), finished: bool, shieldAvailable: bool, shieldActive: bool }`. `shieldAvailable`/`shieldActive` are always present on the model but are only ever set `true`/consulted when the active `RuleSet` is `PowerRuleSet` — under `ClassicRuleSet` they stay permanently `false`/unused, which is how Power Mode stays additive rather than forked.
- **`PlayerState`** — `{ playerId, seatIndex, color, tokens: List<TokenState>, isEliminatedOrFinished }`.
- **`DiceState`** — `{ lastValue: int?, rollsThisTurn: int, awaitingMove: bool }`.
- **`TurnState`** — `{ currentPlayerId, phase: awaitingRoll | awaitingMove | turnEnding, consecutiveSixes: int }`.
- **`GameState`** — the root immutable snapshot: `{ mode: classic | power, board: BoardState, players: List<PlayerState>, dice: DiceState, turn: TurnState, status: inProgress | won, winnerPlayerId? }`.

All of the above are plain immutable Dart classes (`copyWith`-style updates), so a `GameState` can be compared, logged, and — later — JSON-serialized for network transport without any Flutter dependency.

## Engine API (draft)

```dart
class GameEngine {
  GameEngine(GameState initialState, RuleSet ruleSet, DiceEngine dice);

  GameState get state;
  Stream<GameEvent> get events;

  GameEvent rollDice();                 // validates turn phase, asks DiceEngine, applies TurnRules
  GameEvent moveToken(TokenId id);      // validates via MovementRules, applies CaptureRules, WinRules
  GameEvent activateShield(TokenId id); // no-op / rejected under ClassicRuleSet; PowerRules under PowerRuleSet
}
```

- `GameEvent` is a sealed/union type: `DiceRolled(value)`, `NoValidMoves`, `TokenLeftBase`, `TokenMoved(id, from, to)`, `TokenCaptured(capturedId, byId)`, `ShieldBlockedCapture(tokenId)`, `ExtraTurnGranted`, `TurnEnded(nextPlayerId)`, `PlayerFinished(playerId)`, `GameWon(playerId)`, `ActionRejected(reason)`.
- Every mutating method returns the resulting event *and* updates `state` — UI/tests can react to either the event stream (for one-shot effects) or `state` (for persistent rendering), matching the flow diagram in architecture.md.

## Rule modules

- **`MovementRules`** — is a given `(token, diceValue)` move legal (base-exit-needs-six, no-overshoot-past-final-home, finished tokens can't move)? Computes the resulting `progress`.
- **`CaptureRules`** — after a move lands a token on a ring cell, is that cell a safe cell (no capture happens there)? Are there opponent tokens on that non-safe cell? If a capture would occur and Power Mode's Shield is active on the target, block it and emit `ShieldBlockedCapture` instead of `TokenCaptured` (this is the *only* place `PowerRules` hooks into `CaptureRules` — see power-mode.md). Otherwise send captured token(s) back to base (`progress = base sentinel`).
- **`WinRules`** — a player has won once all 4 of their tokens have `finished == true`; sets `GameState.status = won` and rejects any further `rollDice`/`moveToken` calls.
- **`TurnRules`** — rolling a 6 grants an extra roll (tracked via `consecutiveSixes`, with a documented cap — to be finalized/documented in `docs/game-rules.md` at Phase 3 — to prevent an unbounded turn from three 6's in a row, a common Ludo house-rule variant); rolling with no legal move for any token ends the turn immediately (`NoValidMoves` → `TurnEnded`); moving ends the turn unless the roll was a 6.
- **`PowerRules`** — Shield Guard only (Phase 7): tracks each token's one-time `shieldAvailable` flag, exposes `activateShield`, and is consulted by `CaptureRules` as described above. `ClassicRuleSet` simply does not wire this module in at all.

`RuleSet` bundles these into `classic = {Movement, Capture, Win, Turn}` vs `power = classic + PowerRules-aware CaptureRules`. This is the concrete mechanism behind "Classic Mode must remain completely unaffected by Power Mode" — the classic code path has zero reference to the power module.

## Multi-token-per-cell handling (section 19 edge case)

Documented behavior (to be finalized precisely in `docs/game-rules.md` once implemented in Phase 4, following the most common standard Ludo convention unless testing reveals a reason to deviate):
- Multiple of a *player's own* tokens may stack on the same cell freely (no self-capture).
- If a landing token shares a non-safe cell with exactly one opponent token, that opponent is captured.
- If a landing token would share a non-safe cell with *two or more* stacked opponent tokens belonging to the same opponent, the standard convention (a "block") is that the landing token cannot capture and cannot land there — this specific rule will be explicitly confirmed and written into `docs/game-rules.md` before Phase 4 implementation, not assumed silently.

## Why this design satisfies the "engine usable without Flutter widgets" requirement

Every class listed above is constructed and exercised with a `main()` function and `print()` statements alone — no `MaterialApp`, no `BuildContext`, no widget tree. Phases 1–4 will literally do this via a bare debug screen (a `Text` widget dumping `state.toString()` and buttons calling engine methods) specifically so gameplay correctness can be manually verified before any visual investment is made, per the phase-execution philosophy in the brief.
