# Roadmap / Phased Requirements

Each phase is independently usable and verifiable before moving to the next.

---

## Phase 0 — Architecture & Planning ✅
- Research, architecture, pure-Dart engine design, branding, asset registry, and phased roadmap.

## Phase 1 — Flutter Scaffold & Logical Board Model ✅
- Flutter Android scaffold, Riverpod setup, mathematical coordinate & cell path model (`CellId`, `BoardConfig`, `PlayerPath`, `BoardState`).

## Phase 2 — Cryptographic Dice & Token Base Exit ✅
- `Random.secure()` dice engine, state tracking, and base exit validation.

## Phase 3 — Movement & Turn Engine ✅
- Complete movement rules, turn lifecycle, extra turns on 6, and turn advance.

## Phase 4 — Capture & Win System ✅
- Safe cell protection, capture resolution, multi-token blocking, and win detection.

## Phase 5 — Full UI & Screen Flow ✅
- Custom `CustomPainter` board, vector tokens with accessibility markers, animated dice, Splash, Main Menu, Mode Select, Player Select, Pause, and Winner screens.

## Phase 6 — Ludo King Parity, Audio & Polish ✅
- Ludo King tactical turn chaining (resets on kills/home arrivals, 3rd six cap in RNG).
- Classic Mode (4 pawns home) and Quick Mode (2 deployed pawns, 1 pawn home to win, kill required for home entry).
- Multi-token sub-grid clustering on shared/safe cells.
- Auto-move QoL for single legal moves.
- Audio engine with sound effects for roll, token hop, capture, and turn changes.

## Phase 7 — Local Multiplayer Polish & AI Practice (Optional Local Bots)
- Smooth bot player fallback for single player practice against CPU.

## Phase 8 — Backend Scaffold (Node.js + Express + Socket.IO)
- Real-time server scaffold, health-check endpoint, environment config, and room state management.

## Phase 9 — Server-Authoritative Online Gameplay
- Shared/ported rules logic on the server, room create/join/leave, 2–4 player online matches with server-authoritative dice and moves.

## Phase 10 — Disconnect Recovery & Multi-Room Concurrency
- Reconnection token handling, ping/pong heartbeats, and room concurrency validation.

## Phase 11 — MongoDB Persistence & Stats
- MongoDB Atlas integration for match history, player win/loss records, and leaderboards.

## Phase 12 — Cloud Deployment
- Backend deployment on Render with health checks and WebSocket scaling.

## Phase 13 — Player Accounts & Profiles
- OAuth authentication, user profile management, avatar customization, and cross-device stats.
