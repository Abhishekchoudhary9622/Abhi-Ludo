# Changelog

## 2026-08-27 — Phase 0: Architecture & Planning

**Feature:** Initial research, architecture design, branding, Power Mode design, asset shortlist, and phased roadmap. No application code written yet.

**Files/modules changed:**
- `docs/research.md` (new)
- `docs/architecture.md` (new)
- `docs/branding.md` (new)
- `docs/board-system.md` (new)
- `docs/game-engine.md` (new)
- `docs/dice-system.md` (new)
- `docs/power-mode.md` (new)
- `docs/ASSETS.md` (new)
- `docs/project-overview.md` (new)
- `docs/requirements.md` (new)
- `docs/changelog.md` (new, this file)

**Important decisions:**
- State management: Riverpod (`flutter_riverpod` 3.x) — see research.md §1.
- Dice RNG: `Random.secure()` client-side (offline play), server-authoritative `crypto.randomInt` later for online play — see dice-system.md.
- Backend: Node.js + Express + Socket.IO + MongoDB Atlas (free tier) + Render — no Redis/Kafka/Kubernetes.
- Game name (proposed): **Pip Rally** — see branding.md for alternatives and rationale.
- Power Mode mechanic (proposed): **Shield Guard** — see power-mode.md for rejected alternatives (Momentum Boost, Swap Strike).
- Game engine will be fully Flutter/widget-independent (plain Dart classes), consumed by Riverpod notifiers.

**Known issues / deferred:**
- No code exists yet — awaiting approval of this plan before Phase 1.
- Game name / palette are proposals pending your confirmation.
- Trademark clearance for the game name is a lightweight search only, not a formal registry check.

## 2026-08-27 — Phase 1: Flutter scaffold + logical board model

**Feature:** Flutter Android project created, Riverpod wired in, logical board model implemented (cells/paths/safe cells), minimal debug screen to smoke-test the model on-device. No dice, movement, turn, capture, or win logic yet — that's Phases 2-4.

**Environment setup (one-time, this machine):**
- Installed Flutter SDK 3.47.1 (stable channel) at `C:\dev\flutter` (git clone of flutter/flutter).
- Installed Android SDK command-line tools at `C:\Android\sdk` (platforms 35 & 36, build-tools 35.0.0, 28.0.3 & 36.0.0, platform-tools, NDK r28c — the last few pulled automatically by the first Gradle build). All SDK licenses accepted non-interactively.
- Added `C:\dev\flutter\bin`, `C:\Android\sdk\cmdline-tools\latest\bin`, `C:\Android\sdk\platform-tools` to the user PATH, and set `ANDROID_HOME=C:\Android\sdk`, persisted for future sessions/terminals.
- `flutter doctor`: Android toolchain now green. Only remaining doctor warning is an incomplete Visual Studio Windows-desktop install, which is irrelevant since this project targets Android only.

**Files/modules changed:**
- `mobile/` — new Flutter project (`flutter create --platforms android`), package `pip_rally`, org `com.piprally`.
- `mobile/pubspec.yaml` — added `flutter_riverpod: ^3.4.2`.
- `mobile/lib/game/board/cell_id.dart` — `CellId` sealed class: `RingCell`, `HomeLaneCell`, `FinalHomeCell`.
- `mobile/lib/game/board/board_config.dart` — ring size (52), seat entry points, safe-cell rule, `finishProgress` (57).
- `mobile/lib/game/board/player_path.dart` — derives each seat's full path from `BoardConfig`; `cellAt(progress)`, `isInHomeLane`, `isFinished`, `isValidDestination`.
- `mobile/lib/game/board/board_state.dart` — ties config + paths + occupancy index together; `cellFor(token)`, `occupancyIndex(players)`, `opponentsOnCell(...)`.
- `mobile/lib/game/board/board_providers.dart` — Riverpod adapters (`boardStateProvider`, `debugPlayersProvider`) wrapping the plain-Dart board model.
- `mobile/lib/game/state/token_state.dart` — `TokenPosition` sealed (`InBase`/`OnPath`), `TokenState` (includes unused-until-Phase-7 `shieldAvailable`/`shieldActive` fields).
- `mobile/lib/game/state/player_state.dart` — `PlayerState` with 4 tokens per player.
- `mobile/lib/features/home/board_debug_screen.dart` — Phase 1 smoke-test screen only; explicitly not final UI.
- `mobile/lib/main.dart` — wraps app in `ProviderScope`, launches `BoardDebugScreen` directly.
- `mobile/test/widget_test.dart` — replaced default counter-app test with a smoke test for the debug screen (wrapped in its own `ProviderScope`).

**Important decisions:**
- Confirmed no Flutter import anywhere under `lib/game/` (board/state files are plain Dart) — verified by code review of each file; enforced going forward per architecture.md.
- Board path generation is table-driven from one `BoardConfig`, not four hand-written per-player paths, per board-system.md.
- Debug screen intentionally unstyled/ugly — visual investment starts Phase 5.

**Verification performed:**
- `flutter analyze`: 0 issues.
- `flutter test`: 1/1 passed.
- `flutter build apk --debug`: succeeded, produced `mobile/build/app/outputs/flutter-apk/app-debug.apk` (153MB, expected size for an unoptimized multi-ABI debug build).

**Known issues / deferred:**
- No dice, movement, turn, capture, or win logic yet (Phases 2-4).
- Debug screen is not the real UI and will be replaced/removed once Phase 5 lands.
- Safe-cell offset and multi-token-stacking capture behavior are placeholder/documented-as-provisional in board-system.md pending Phase 4 finalization into `docs/game-rules.md`.

## 2026-08-27 — Phase 2: Dice engine + token leave-base wiring

**Feature:** Cryptographically-secure `DiceEngine` implemented and wired into the debug screen with a working "Roll Dice" button; tokens can now be manually moved out of base once a 6 is rolled. Still headless/debug-UI — no real `MovementRules`/`TurnRules`/`GameEngine` yet (Phase 3).

**Files/modules changed:**
- `mobile/lib/game/dice/random_source.dart` — `RandomSource` interface + `SecureRandomSource` (`Random.secure()`, with a logged, non-silent fallback to `Random()` if secure entropy is ever unavailable).
- `mobile/lib/game/dice/dice_engine.dart` — `DiceEngine.roll()`, returns 1..6, no game-rule knowledge, no player-identifying arguments (structurally fair per docs/dice-system.md).
- `mobile/lib/game/dice/dice_providers.dart` — Riverpod adapters (`randomSourceProvider`, `diceEngineProvider`) over the plain-Dart dice classes.
- `mobile/lib/game/state/dice_state.dart` — `DiceState` (lastValue, rollsThisTurn, awaitingMove).
- `mobile/lib/game/state/debug_game_notifier.dart` — `DebugGameNotifier`, an explicitly-labeled throwaway Phase 2 scratch controller (not the real engine) that lets the debug screen call `rollDice()` and `leaveBase()`. Documented in-code as deleted once Phase 3's real `GameEngine`/`TurnRules`/`MovementRules` land.
- `mobile/lib/features/home/board_debug_screen.dart` — added dice roll/reset buttons and per-token "Leave base" buttons (enabled only when the last roll is 6).
- `mobile/test/widget_test.dart` — updated title assertion for the Phase 2 screen; added a test that tapping "Roll Dice" updates the displayed last-roll value.

**Important decisions:**
- Used `Random.secure()` uniformly (not a plain seedable RNG) even for local pass-and-play, per docs/dice-system.md's reasoning: one consistent, defensible dice implementation rather than two different RNGs for offline vs future online modes.
- `DebugGameNotifier` intentionally has zero turn enforcement (no "one roll per turn", no move validation) — it is explicitly *not* a preview of Phase 3's rules, just enough state-mutation to manually verify `DiceEngine` and the `TokenState` base-exit transition on a real device.

**Verification performed:**
- `flutter analyze`: 0 issues.
- `flutter test`: 2/2 passed (screen renders; rolling dice updates the displayed value).
- `flutter build apk --debug`: succeeded.

**Known issues / deferred:**
- No dice-value-other-than-6 movement, no capture, no turn/extra-six logic, no win detection yet — all Phase 3/4.
- `DebugGameNotifier` will be removed once the real engine exists; it is not production code and is documented as such in its own doc comment.

## 2026-08-27 — Phase 3: Movement + Turn engine

**Feature:** Real `MovementRules`, `TurnRules`, `TurnState`, `RuleSet`, `GameState`, `GameEvent`, and `GameEngine` implemented, replacing the throwaway Phase 2 `DebugGameNotifier`. This is a fully playable, headless Classic-mode movement/turn loop (still no capture/win yet — that's Phase 4, done in the same pass, see below).

**Files/modules changed:**
- `mobile/lib/game/rules/movement_rules.dart` — `canMove`, `resultingProgress`, `legalTokenIds`; enforces base-exit-needs-six and no-overshoot-into-home.
- `mobile/lib/game/state/turn_state.dart` — `TurnState`, `TurnPhase` (awaitingRoll/awaitingMove).
- `mobile/lib/game/rules/turn_rules.dart` — `afterRoll`/`afterMove`; extra turn on 6, no-legal-move ends turn, three-consecutive-sixes forfeit (documented as a chosen house-rule variant in `docs/game-rules.md`).
- `mobile/lib/game/rules/rule_set.dart` — `RuleSet`/`GameMode` bundling movement/capture/win/turn modules; `RuleSet.classic`/`RuleSet.power` factories (Power just reuses the same modules — no fork).
- `mobile/lib/game/engine/game_state.dart` — root immutable `GameState` snapshot.
- `mobile/lib/game/engine/game_event.dart` — `GameEvent` union (DiceRolled, TokenMoved, TurnEnded, ActionRejected, etc).
- `mobile/lib/game/engine/game_engine.dart` — `GameEngine.rollDice()`/`moveToken()`, delegates entirely to `RuleSet`, emits events via a broadcast stream, exposes `legalMovesForCurrentPlayer()` for UI.
- `mobile/lib/game/engine/game_factory.dart` — `createGameEngine()`, builds a fresh 4-seat Classic match.
- `mobile/lib/game/engine/game_providers.dart` — `GameNotifier`/`gameProvider`, the real Riverpod adapter over `GameEngine` (no rules logic in the notifier itself).
- Deleted `mobile/lib/game/state/debug_game_notifier.dart` (Phase 2 throwaway, explicitly documented as superseded once the real engine existed).

## 2026-08-27 — Phase 4: Capture + Win rules

**Feature:** `CaptureRules` and `WinRules` implemented and wired into `GameEngine.moveToken()`, completing a fully playable, correct, headless Classic Mode (section 25's "complete the entire game locally" milestone, minus visuals/audio which are Phase 5-6).

**Files/modules changed:**
- `mobile/lib/game/rules/capture_rules.dart` — `CaptureOutcome` (`NoCapture`/`Captured`/`ShieldBlocked`), `isBlocked` (multi-token-stacking block rule), `resolve` (capture resolution honoring safe cells and, structurally, future Power Mode shields).
- `mobile/lib/game/rules/win_rules.dart` — `WinRules.checkWinner`.
- `mobile/lib/game/engine/game_engine.dart` — `moveToken()` now checks `isBlocked` before applying a move, resolves capture after landing, sends captured tokens back to base, checks for a winner after every move, and locks the engine (`ActionRejected`) once `GameStatus.won`.
- `mobile/lib/features/home/board_debug_screen.dart` — rewritten to drive the real `GameEngine` via `gameProvider` (roll/move buttons, current-turn indicator, last-event display, winner banner). Deleted the old Phase 1-2 board-only debug screen content.
- Deleted `mobile/lib/game/board/board_providers.dart` (Phase 1 standalone board provider, superseded by `gameProvider` which owns board+players together).
- `docs/game-rules.md` (new) — finalizes exact safe-cell placement, capture-blocking rule, and three-sixes forfeit as actually implemented, superseding the "TBD" language in `docs/board-system.md`/`docs/game-engine.md`.

**Important decisions:**
- Multi-token-stacking capture edge case (section 19) resolved as: 2+ of the same opponent's tokens on a non-safe cell blocks that cell entirely (move rejected), matching common Ludo convention — see `docs/game-rules.md`.
- Per user instruction, automated widget tests are no longer being written/maintained each phase; `mobile/test/widget_test.dart` was deleted rather than kept in sync. Compile correctness is still verified via `flutter analyze` (0 issues) and a debug APK build (succeeded) after each phase.

**Verification performed:**
- `flutter analyze`: 0 issues (after this phase's changes).
- `flutter build apk --debug`: succeeded.

**Known issues / deferred:**
- Power Mode / Shield Guard not implemented yet (Phase 7) — `CaptureRules` already has the structural hook (`shieldActive` check) but nothing ever sets that flag yet.
- 2-3 human-player seat-skipping not implemented — all 4 seats always take turns for now; real player-count selection arrives with Phase 5 UI.
- No real UI/visuals/audio yet — debug screen remains intentionally plain.

## 2026-08-27 — Phase 5: Real board/token/dice UI, screen flow, animations

**Feature:** Replaced the debug screen entirely with the real UI: splash, main menu, mode select, player select (2-4), game screen (rendered board/tokens/dice), pause dialog, and winner screen — matching section 21's screen list minus login/profile/matchmaking (explicitly deferred). Applied the branding.md palette/typography groundwork (Phase 6 will add the actual Fredoka/Nunito font files and audio). Board/tokens/dice are all custom-drawn (no image assets), per the originality requirement.

Also fixed a gap noticed while building this phase: local play needs to support 2-4 players (section 1), which requires the turn engine to skip inactive seats — this was added to `PlayerState`/`TurnRules`/`WinRules`/`GameEngine`/`game_factory.dart` as part of this phase rather than deferred, since the player-select screen needed it to function correctly.

**Files/modules changed:**
- `mobile/lib/game/state/player_state.dart` — added `isActive` flag.
- `mobile/lib/game/rules/turn_rules.dart` — `afterRoll`/`afterMove` now take `activeSeats` and skip inactive seats when advancing turn order.
- `mobile/lib/game/rules/win_rules.dart` — only checks active players for a winner.
- `mobile/lib/game/engine/game_engine.dart` — computes and passes `activeSeats` to `TurnRules`.
- `mobile/lib/game/engine/game_factory.dart` — `createGameEngine` now takes `playerCount` (2-4), marking seats `playerCount..3` inactive.
- `mobile/lib/game/engine/game_providers.dart` — added `MatchConfig`/`matchConfigProvider` (mode + player count, set by the player-select screen before the game screen builds its engine).
- `mobile/lib/config/app_theme.dart` (new) — centralized color/text/button theme per docs/branding.md.
- `mobile/lib/features/game/board/board_layout.dart` (new) — pure rendering-only mapping from logical `CellId` to a 15x15 grid position (seat 0's ring/lane geometry rotated per seat; explicitly never imported by anything under `lib/game/`).
- `mobile/lib/features/game/board/board_painter.dart` (new) — `CustomPainter` drawing the board (yards, ring cells with pip-flower safe-cell glyphs, home lanes, 4-triangle center) from the logical board + layout — no board image asset.
- `mobile/lib/features/game/board/board_widget.dart` (new) — sizes/positions the painter and a token layer together.
- `mobile/lib/features/game/board/token_widget.dart` (new) — vector token (colored circle + accessibility shape marker per docs/branding.md), animates position via `AnimatedPositioned`/scale via `AnimatedScale` — reflects `GameState`, never decides logic.
- `mobile/lib/features/game/widgets/dice_widget.dart` (new) — custom-drawn pip-face die with a squash-and-stretch + pip-shuffle roll animation; shuffle is decorative only, real value always comes from `GameEngine`.
- `mobile/lib/features/game/game_screen.dart` (new) — the real game screen, replacing the debug screen.
- `mobile/lib/features/game/pause_dialog.dart`, `winner_screen.dart` (new).
- `mobile/lib/features/home/splash_screen.dart`, `main_menu_screen.dart`, `mode_select_screen.dart`, `player_select_screen.dart` (new).
- `mobile/lib/features/settings/settings_screen.dart` (new) — intentionally has no mute toggle yet since audio doesn't exist until Phase 6 (avoids a placeholder control per section 51's "no placeholder features" rule).
- `mobile/lib/main.dart` — now launches `SplashScreen` with `AppTheme.theme` instead of the Phase 1-4 debug screen.
- Deleted `mobile/lib/features/home/board_debug_screen.dart` (fully superseded).

**Important decisions:**
- Power Mode selection currently plays identically to Classic (documented on-screen in `ModeSelectScreen` and in code comments) since Shield Guard isn't implemented yet — not presented as a finished feature, per section 51.
- Board/token/dice visuals are 100% vector (`CustomPainter`/widgets), no image assets used or needed for the game's signature art, consistent with `docs/ASSETS.md`.
- Per user direction, no automated widget tests were written for this phase; verification was `flutter analyze` (0 issues) + a successful debug APK build.

**Verification performed:**
- `flutter analyze`: 0 issues.
- `flutter build apk --debug`: succeeded.

**Known issues / deferred:**
- Fonts are still the Flutter default (Roboto) — Fredoka/Nunito bundling is Phase 6.
- No sound effects/music yet — Phase 6.
- No capture/turn-transition/power-activation animation beyond token movement and the dice roll — richer animation polish is part of Phase 6.
- Settings screen has no content yet beyond a note explaining why (audio not implemented).

## 2026-08-28 — Phase 6: Ludo King Mechanics, Audio, Clustering & Auto-Move

**Feature:** Overhauled game mechanics, dice RNG, turn management, and game modes to match modern production Ludo King parity. Removed Shield Guard / experimental mechanics completely.

**Mechanics & Rules Implemented:**
- **Bonus Roll Chaining with Tactical Resets:** Rolling a `6` gives an extra roll. Capturing an opponent or finishing a pawn into the home triangle gives a bonus roll AND resets the consecutive 6s counter to 0, allowing tactical chaining like `6 -> 6 -> Kill -> 6`.
- **3rd Six Prevention:** Constrains 3rd consecutive roll to `1..5` via cryptographic RNG so a 3rd six is never rolled without an intermediate reset.
- **Game Modes:**
  - **Classic Mode:** 4 pawns start in base; 4 pawns needed to win; free home entrance.
  - **Quick Mode:** 2 pawns start deployed on track; 1 pawn to win; kill strictly required to enter the home corridor.
- **Multi-Token Sub-Grid Layout:** Shared cells (safe stars and track cells) dynamically arrange 2-4 tokens in a neat sub-grid without overlapping.
- **Auto-Move QoL:** If exactly 1 legal move is available, the game auto-moves the pawn with a 380ms delay.
- **Audio Engine:** `AudioService` with `audioplayers` package playing sound effects for dice rolls, token hops, captures, and turn changes.
- **OFL Fonts:** Registered Fredoka and Nunito fonts with `LicenseRegistry`.

**Files/modules changed:**
- `mobile/pubspec.yaml` — added `audioplayers: ^6.1.0`.
- `mobile/lib/core/audio/audio_service.dart` (new) — central audio controller.
- `mobile/lib/game/dice/dice_engine.dart` — added `allowSix` parameter.
- `mobile/lib/game/state/token_state.dart` — stripped all shield fields.
- `mobile/lib/game/state/player_state.dart` — added `kills` tracking and `finishedTokensCount`.
- `mobile/lib/game/rules/rule_set.dart` — defined `GameMode.classic` and `GameMode.quick`.
- `mobile/lib/game/rules/movement_rules.dart` — added Quick Mode kill-to-enter-home lock.
- `mobile/lib/game/rules/capture_rules.dart` — simplified without shields.
- `mobile/lib/game/rules/win_rules.dart` — dynamic `tokensToWin` support.
- `mobile/lib/game/rules/turn_rules.dart` — tactical chaining with `BonusRollReason`.
- `mobile/lib/game/engine/game_event.dart` — updated events and bonus turn reasons.
- `mobile/lib/game/engine/game_engine.dart` — full Ludo King rule execution and 3rd six cap.
- `mobile/lib/game/engine/game_factory.dart` — Quick Mode 2-token initial deployment.
- `mobile/lib/features/home/mode_select_screen.dart` — Classic & Quick mode selection cards.
- `mobile/lib/features/game/board/token_widget.dart` — multi-token cluster layout and pulse animation.
- `mobile/lib/features/game/game_screen.dart` — HUD, audio triggers, auto-move, and bonus banners.
- `mobile/lib/main.dart` — fixed `LicenseRegistry` foundation import.
- `docs/game-rules.md`, `docs/requirements.md`, `docs/changelog.md`, `README.md`.

**Verification performed:**
- `flutter analyze`: 0 issues found.

## 2026-08-28 — Phase 7 & 8: Smart AI Bots, Career Profile, Settings & Real-Time Multiplayer Backend

**Feature:** Complete commercial-grade feature suite added:
1. **Play Vs Computer (Smart AI Bots):** Single-player match against 1–3 AI bots driven by tactical heuristic scoring (`BotController`).
2. **Career Profile & Persistent Stats:** `StatsRepository` storing match history, wins, kills, win rate, custom player nickname, and avatar selection via `SharedPreferences`.
3. **Settings & Interactive Rulebook:** Audio toggles, "How to Play" bottom sheet, and open-source licenses dialog.
4. **Real-Time Multiplayer Server (`server/`):** Node.js, Express, and Socket.IO server with 6-digit room codes, server-authoritative room state, `/health` endpoint, Dockerfile, and `render.yaml` deployment configuration.
5. **Flutter Online Client (`mobile/lib/networking/`):** `SocketService` and `OnlineLobbyScreen` for creating and joining private multiplayer rooms in real time.

**Files/modules changed:**
- `mobile/lib/game/ai/bot_controller.dart` (new) — smart heuristic decision engine.
- `mobile/lib/game/state/player_state.dart` — added `isBot` flag.
- `mobile/lib/game/engine/game_factory.dart` — bot seat configuration.
- `mobile/lib/game/engine/game_providers.dart` — updated `MatchConfig` with bot parameters.
- `mobile/lib/features/game/game_screen.dart` — automated bot turns with natural delays.
- `mobile/lib/features/home/bot_setup_screen.dart` (new) — AI bot opponent selection.
- `mobile/lib/core/stats/stats_repository.dart` (new) — persistent career stats manager.
- `mobile/lib/features/profile/profile_screen.dart` (new) — player profile and stats dashboard.
- `mobile/lib/features/settings/settings_screen.dart` — SFX toggle and interactive rulebook.
- `mobile/lib/features/home/main_menu_screen.dart` — full menu linking all game modes.
- `mobile/lib/features/game/winner_screen.dart` — automatic career stats recording.
- `server/package.json`, `server/src/server.js`, `server/src/game_room.js`, `server/src/room_manager.js`, `server/Dockerfile`, `server/render.yaml` (new).
- `mobile/lib/networking/socket_service.dart` (new).
- `mobile/lib/features/online/online_lobby_screen.dart` (new).

**Verification performed:**
- `flutter analyze`: 0 issues found across all mobile files.
- `npm install` and server startup verified on `localhost:3000`.
- Health-check `GET /health` verified responding with HTTP 200 `{ status: "ok" }`.


