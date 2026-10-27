# Architecture

## 1. Project structure

Following the structure proposed in the brief, with one adjustment: an explicit `packages` boundary is *not* introduced (a full Dart package split is unnecessary complexity for this project's size — a well-organized `lib/` with clear folder boundaries is enough, per the "no unnecessary complexity" priority). Everything lives in one Flutter app under `mobile/`.

```
LUDO/
├── mobile/                        # Flutter app (Android target)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                  # cross-cutting: constants, extensions, error types
│   │   ├── config/                # theme/design tokens, env/build config, routes
│   │   ├── models/                # shared plain-Dart data models (Player, MatchResult, etc.)
│   │   ├── game/                  # the game ENGINE — no Flutter imports allowed here
│   │   │   ├── board/             # LogicalBoard, Cell, PathDefinition
│   │   │   ├── engine/            # GameEngine, GameState, event types
│   │   │   ├── rules/             # MovementRules, CaptureRules, WinRules, RuleSet, PowerRules
│   │   │   ├── dice/              # DiceEngine, RandomSource
│   │   │   └── state/             # PlayerState, TokenState, TurnState, DiceState
│   │   ├── features/              # UI, organized by screen/feature
│   │   │   ├── home/              # splash, main menu, mode/player select
│   │   │   ├── game/               # game screen, board widget, token widget, dice widget, pause, winner
│   │   │   ├── settings/
│   │   │   └── profile/           # placeholder folder only, empty until Phase 13
│   │   ├── networking/            # Socket.IO client wrapper, REST client (added Phase 8+)
│   │   ├── widgets/                # shared reusable widgets (buttons, cards, dialogs)
│   │   └── main.dart
│   └── assets/                     # fonts, sfx, images (only license-cleared files)
│
├── server/                         # Node.js backend (added starting Phase 8)
│   ├── src/
│   │   ├── config/
│   │   ├── game/
│   │   ├── rooms/
│   │   ├── socket/
│   │   ├── api/
│   │   ├── models/
│   │   ├── database/
│   │   ├── auth/                   # added Phase 13
│   │   └── server.js
│   └── package.json
│
├── docs/
├── README.md
└── .gitignore
```

**Hard rule enforced by code review at every phase:** nothing under `lib/game/` imports `package:flutter/...`. The engine is pure Dart so it is usable headlessly (and, if ever needed, portable to a server-side Dart process without change). `lib/features/` is the only place Flutter widgets exist, and it depends on `lib/game/` — never the reverse.

## 2. State management: Riverpod

See `docs/research.md` §1 for the comparison and reasoning. Concretely:

- The engine layer (`lib/game/`) has zero knowledge of Riverpod or Flutter. `GameEngine` is a plain class with methods like `rollDice()`, `moveToken(tokenId)`, exposing an immutable `GameState` snapshot and a stream/callback of `GameEvent`s.
- A single `NotifierProvider<GameController, GameState>` in `lib/features/game/` wraps a `GameEngine` instance: UI calls (e.g. "roll dice" button pressed) become calls to controller methods, which delegate to the engine and then update the exposed `GameState`.
- Widgets use `ConsumerWidget`/`ref.watch(gameControllerProvider)` to rebuild on state changes — no manual `setState`, no business logic inside widgets.
- This means the entire engine can be unit-exercised (manually, via a debug screen, or later via simple Dart scripts) without instantiating any widget — which is exactly the debug-UI approach used in Phases 1–4 before real UI exists.

## 3. Engine flow (per section 11)

```
USER ACTION (UI event, or later: server-relayed event)
      │
      ▼
GameController (Riverpod notifier) — thin adapter, no rules logic
      │
      ▼
GameEngine.rollDice() / .moveToken(id) / .activateShield(id)
      │
      ▼
RuleSet (ClassicRuleSet or PowerRuleSet) — validates the action
      │
      ▼
  valid? ──no──▶ return a rejected GameEvent (e.g. InvalidMove), state unchanged
      │yes
      ▼
State update (new immutable GameState computed from old state + action)
      │
      ▼
GameEvent emitted (DiceRolled, TokenMoved, TokenCaptured, TurnEnded, GameWon, ...)
      │
      ▹ UI layer reacts to GameEvent to drive one-shot effects (play a capture animation,
        show a snackbar) while GameState itself drives the persistent rendering.
```

`RuleSet` is an interface implemented by `ClassicRuleSet` and `PowerRuleSet` (which wraps `ClassicRuleSet` and adds Shield Guard hooks — see `docs/game-engine.md` and `docs/power-mode.md`). The engine is constructed with whichever `RuleSet` the selected mode requires; Classic Mode literally cannot execute Power Mode code because `ClassicRuleSet` never references it.

## 4. Determinism

Given the same starting `GameState` and the same sequence of external inputs (dice values + move choices), the engine produces the same resulting `GameState` — there is no hidden mutable global state, no `DateTime.now()`-based branching in rules, and the only nondeterminism (the dice roll itself) is isolated behind the `RandomSource` interface (see `docs/dice-system.md`). This determinism is what makes server-authoritative multiplayer straightforward later: the server runs the identical rules module against a dice value *it* generated, and simply broadcasts the resulting state/events — clients never compute their own authoritative outcome.

## 5. Future server-authoritative architecture (design now, build later — Phase 9+)

- The server keeps one in-memory `GameEngine` instance per active room (keyed by `roomId`). This mirrors the same rules layer described above; if the server ends up being Node/JS rather than Dart, the *rules* (not the code) are kept identical by treating `docs/game-rules.md` — written once real Classic/Power rules are finalized in Phase 4/7 — as the single source of truth both implementations must match, and by manual verification play-testing both.
- Client → server messages are intents only: `ROLL_DICE`, `MOVE_TOKEN { tokenId }`, `ACTIVATE_SHIELD { tokenId }`. The client never sends a dice value or a resulting position.
- Server validates: is this socket the current turn's player? Is this a legal action given current `TurnState`/`DiceState`? If yes, it generates the dice value itself (`crypto.randomInt(1,7)`), runs it through the same rules logic, updates the room's `GameState`, and broadcasts the resulting event + minimal state delta to all sockets in that room (not the entire state blob every time, per the performance guidance in section 44).
- This is exactly why the engine has no Flutter/UI coupling from day one — it keeps the option of a genuinely shared rules implementation open, and even if the server ends up being reimplemented in JS, the Dart engine's explicit, UI-free API surface makes it a precise spec to port from.

## 6. Handling 50–100 concurrent users (per section 30)

- Estimated ~20–30 concurrent rooms at peak (2–4 players/room). A single Node.js process holding that many small in-memory `GameState` objects (a few KB each) plus Socket.IO connections is well within a single small server instance's capacity — no horizontal scaling, no message queue, no Redis pub/sub needed at this scale.
- Socket.IO's own room feature (`socket.join(roomId)` / `io.to(roomId).emit(...)`) is used directly for the isolation described in section 28 — one room's broadcasts never reach another room's sockets. No custom pub/sub layer needed.
- If the app ever needs multiple server processes (well beyond current scale), Socket.IO's documented adapter mechanism (e.g. a Redis adapter) is the standard next step — but that is explicitly **not** built now, only noted here as the documented extension point so the architecture doesn't paint us into a corner.
- MongoDB is kept off the hot path entirely (see `docs/research.md` §4) — writes happen only at match end (results) and on explicit stat reads, not on every dice roll/move, keeping both DB load and network chatter low.

## 7. Why not more infrastructure

Per section 30/52's explicit instruction, Kubernetes, microservices, Kafka, Redis, and multi-cluster setups are deliberately excluded from the current design. A single Express + Socket.IO Node process, one MongoDB Atlas free cluster, and one Render web service comfortably cover the stated 50–100 concurrent user target with room to spare.
