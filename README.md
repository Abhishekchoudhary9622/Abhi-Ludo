# Abhi Ludo 🎲

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Socket.IO](https://img.shields.io/badge/Socket.io-4.x-010101?style=for-the-badge&logo=socketdotio&logoColor=white)](https://socket.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](CONTRIBUTING.md)

**A production-grade, full-featured Ludo board game built with Flutter, Riverpod, and Node.js Socket.IO.**  
*Featuring a decoupled pure-Dart rules engine, true Ludo King parity mechanics, smart offline AI bots, real-time online multiplayer, career statistics, dynamic multi-token clustering, and 100% vector-rendered board graphics.*

[Features](#-key-features) • [Game Rules](#-game-rules--modes) • [Architecture](#-architecture--tech-stack) • [Quick Start](#-quick-start) • [Multiplayer Protocol](#-real-time-multiplayer-protocol) • [Documentation](#-documentation)

</div>

---

## 📌 Project Overview

**Abhi Ludo** is an open-source, commercial-grade digital board game engineered from first principles with modern software craftsmanship:

- 🎮 **Pass & Play:** Same-device local multiplayer for 2 to 4 players.
- 🤖 **Play Vs Computer:** Practice offline against 1 to 3 smart AI bots driven by tactical heuristic scoring.
- 🌐 **Real-Time Online Multiplayer:** Private room creation with 6-digit codes, player lobbies, and live gameplay over WebSockets.
- 🏆 **Ludo King Parity Mechanics:** True bonus roll chaining on rolling a 6, capturing opponents, and home arrivals, with tactical consecutive-6 resets and cryptographic 3rd six cap.
- ⚡ **Classic & Quick Modes:** Full traditional 4-token marathon or fast-paced 2-token pre-deployed sprint with mandatory capture corridor unlock.
- 📊 **Career Profile & Statistics:** Persistent records of matches played, victories, total captures, win rate %, and custom avatar selector.
- 🎨 **100% Vector Visuals:** Pixel-perfect `CustomPainter` rendering of the board, animated 3D-feel dice, and dynamic multi-token sub-grid clustering on safe cells.
- 🔊 **Rich Low-Latency Audio:** Immersive sound effects for dice rolls, token hops, captures, and victory fanfares with instant mute toggles.

---

## ✨ Key Features

| Category | Capability | Description |
|---|---|---|
| **Modes** | Pass & Play | 2, 3, or 4 local human players on a single device. |
| **Modes** | Vs AI Bots | 1–3 tactical bots evaluating kill potential, threat evasion, and home sprints. |
| **Modes** | Online Multiplayer | Create or join private rooms using 6-digit room codes. |
| **Rules** | Classic Mode | Traditional 4-token race with full track traversal. |
| **Rules** | Quick Mode | 2 tokens pre-deployed; mandatory kill required before entering home corridor. |
| **Dice** | Cryptographic RNG | Backed by `Random.secure()` with fair distribution and zero rigging. |
| **Dice** | 3rd Six Prevention | Guaranteed cap preventing frustrating 3 consecutive sixes unless reset by kill. |
| **Board** | Safe Cells | 4 starting stations + 4 star/pip cells granting total capture immunity. |
| **Board** | Token Clustering | 2–4 tokens sharing a cell dynamically arrange into an uncluttered sub-grid. |
| **Profile** | Career Stats | Persistent tracking of wins, win rate, and captures stored via `SharedPreferences`. |
| **Design** | Vector Rendering | Crisp resolution independence on any mobile screen density. |
| **Audio** | Sound Effects | Native sound feedback with OFL/CC0 verified licenses. |

---

## 🎮 Game Rules & Modes

### Game Modes

```
┌─────────────────────────────────────────────────────────────┐
│                       CLASSIC MODE                          │
│  - 4 tokens start inside player base                        │
│  - Traverses entire 52-cell track + 5-step home lane        │
│  - Free entrance into home corridor                         │
│  - First player to get all 4 tokens home wins!             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        QUICK MODE                           │
│  - Fast-paced 5–10 minute matches                           │
│  - 2 tokens start already deployed at track progress 0      │
│  - Capture Lock: Must capture at least 1 opponent token     │
│    to unlock your colored home corridor!                    │
│  - First player to bring 1 token home wins!                 │
└─────────────────────────────────────────────────────────────┘
```

### Turn & Bonus Roll Tactics

1. **Base Exit on 6:** Requires rolling a 6 to bring a pawn out of the yard onto the track.
2. **Bonus Turns (Extra Rolls):**
   - **Rolling a 6:** Grants an extra turn.
   - **Capturing an Opponent (Kill):** Grants an immediate bonus roll **AND resets the consecutive-6 counter**.
   - **Pawn Reaching Home:** Grants a bonus roll **AND resets the consecutive-6 counter**.
3. **Tactical Chaining & 3rd Six Cap:**
   - Tactical moves (Kill or Home Arrival) reset the consecutive-6 counter to 0, enabling sequences like `6 -> 6 -> Kill -> 6`.
   - If two 6s are rolled consecutively without a kill or home reset, the dice engine guarantees the 3rd roll is chosen from `1..5`.
4. **Safe Star Cells:**
   - 4 player base exit cells + 4 star cells are immune to captures.
5. **Multi-Token Clustering:**
   - When multiple pawns occupy the same safe cell, they dynamically scale into a mini sub-grid so all players remain visible and tap-selectable.

---

## 🏛 Architecture & Tech Stack

```
   ┌─────────────────────────────────────────────────────────────────┐
   │                       Flutter Mobile App                        │
   │  ┌──────────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
   │  │   UI & Vector Board  │  │  Riverpod State │  │ Socket.IO   │ │
   │  │ (CustomPainters, SFX)│  │   Notifiers     │  │   Client    │ │
   │  └──────────▲───────────┘  └────────▲────────┘  └──────▲──────┘ │
   │             │                       │                  │        │
   │  ┌──────────┴───────────────────────┴────────────────┐ │        │
   │  │          Pure Dart Offline Game Engine            │ │        │
   │  │    (Rules, Board, Dice, AI Heuristics Engine)     │ │        │
   │  │          * Zero Flutter UI Dependencies *         │ │        │
   │  └───────────────────────────────────────────────────┘ │        │
   └────────────────────────────────────────────────────────┼────────┘
                                                            │ WebSockets
   ┌────────────────────────────────────────────────────────▼────────┐
   │             Real-Time Multiplayer Server (Node.js)              │
   │   (Express, Socket.IO, Room Manager, Authoritative Engine)      │
   └─────────────────────────────────────────────────────────────────┘
```

- **Client:** Flutter 3.x / Dart (Android-first, iOS/Web/Desktop capable).
- **State Management:** Riverpod (`flutter_riverpod` 3.x) with immutable state and pure notifier providers.
- **Rules Engine:** Pure Dart in `mobile/lib/game/` with zero Flutter dependencies for instant headless unit testing.
- **Backend:** Node.js, Express, Socket.IO.
- **Bot AI:** Heuristic evaluation function scoring moves based on capture reward, threat avoidance, and track advancement.
- **Audio:** `audioplayers` for low-latency SFX playback.

---

## 📁 Codebase Structure

```
Abhi-Ludo/
├── .github/                          # GitHub Actions CI & Issue Templates
│   ├── workflows/ci.yml              # Automated Flutter test/lint & Node checks
│   └── ISSUE_TEMPLATE/               # Bug report & feature request templates
│
├── docs/                             # Complete Architectural Specifications
│   ├── ASSETS.md                     # Bundled audio & font licensing (OFL, CC0)
│   ├── architecture.md               # Decoupled engine design & layer separation
│   ├── board-system.md               # Logical geometry & coordinate mapping
│   ├── branding.md                   # Color tokens, accessibility markers, themes
│   ├── changelog.md                  # Granular milestone development history
│   ├── dice-system.md                # Cryptographic RNG specifications
│   ├── game-engine.md                # State machines, turn lifecycle, and events
│   ├── game-modes.md                 # Classic vs Quick mode technical specs
│   ├── game-rules.md                 # Full Ludo King parity rulebook
│   ├── power-mode.md                 # Power mode design concept
│   ├── project-overview.md           # Executive summary & index
│   ├── requirements.md               # Phased roadmap and requirements
│   └── research.md                   # Research backing technology choices
│
├── mobile/                           # Flutter Mobile Application
│   ├── assets/                       # Bundled fonts & sound effects
│   ├── lib/
│   │   ├── config/                   # App theme, colors, accessibility
│   │   ├── core/                     # Audio service & stats persistence
│   │   ├── features/                 # UI screens (Game, Lobby, Profile, Settings)
│   │   ├── game/                     # PURE DART GAME ENGINE (No UI imports)
│   │   │   ├── ai/                   # Smart Bot heuristic controller
│   │   │   ├── board/                # BoardConfig, CellId, PlayerPath
│   │   │   ├── dice/                 # RandomSource, DiceEngine, 3-sixes cap
│   │   │   ├── engine/               # GameEngine, GameState, GameProviders
│   │   │   └── rules/                # Movement, capture, chaining, win rules
│   │   ├── networking/               # Socket.IO client service
│   │   └── main.dart                 # App bootstrap
│   └── test/                         # Unit & engine tests
│
├── server/                           # Node.js Multiplayer Backend
│   ├── src/
│   │   ├── game_room.js              # Authoritative room state machine
│   │   ├── room_manager.js           # 6-digit room code manager
│   │   └── server.js                 # Express + Socket.IO server & /health
│   ├── Dockerfile                    # Container configuration
│   ├── package.json                  # Dependencies
│   └── render.yaml                   # Cloud deployment blueprint
│
├── scripts/
│   └── generate_sfx.js               # Audio synthesis script
│
├── CONTRIBUTING.md                   # Guidelines for contributors
├── CODE_OF_CONDUCT.md                # Community code of conduct
├── LICENSE                           # MIT License
├── SECURITY.md                       # Security vulnerability policy
└── README.md                         # Main repository documentation
```

---

## 🚀 Quick Start

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.1`)
- [Node.js](https://nodejs.org/) (`>= 18.x`)
- Android Studio / VS Code with Flutter extension
- Android Device or Emulator (API level 21+)

### 2. Run the Mobile Client

```bash
cd mobile

# Get Flutter packages
flutter pub get

# Verify codebase health
flutter analyze

# Run unit tests
flutter test

# Launch on connected device/emulator
flutter run

# (Optional) Build release APK
flutter build apk --release
```

### 3. Run the Multiplayer Backend

```bash
cd server

# Install Node dependencies
npm install

# Start the server (binds to port 3000)
npm start

# Verify health status
curl http://localhost:3000/health
```

---

## 🔌 Real-Time Multiplayer Protocol

The backend uses Socket.IO with bidirectional event routing:

### Client -> Server
- `create_room` (`{ playerName, mode, maxPlayers }`): Initialize a room with a 6-digit code.
- `join_room` (`{ roomCode, playerName }`): Join room lobby.
- `start_game` (`{ roomCode }`): Host triggers match start.
- `roll_dice` (`{ roomCode }`): Active player rolls the dice.
- `move_token` (`{ roomCode, tokenId }`): Active player selects token to move.
- `leave_room` (`{ roomCode }`): Gracefully exit room.

### Server -> Client
- `player_joined` / `player_left`: Real-time lobby member updates.
- `game_started`: Broadcasts board initialization to all clients.
- `dice_rolled`: Syncs dice roll value and remaining consecutive sixes.
- `token_moved`: Syncs pawn movement, captures, and home arrivals.
- `turn_changed`: Advances turn to the next player.
- `turn_timeout`: Auto-passes turn when 15-second timer expires.
- `game_over`: Broadcasts winner and final rankings.

---

## 🐳 Docker Deployment

You can run the backend server in Docker:

```bash
cd server
docker build -t abhi-ludo-server .
docker run -p 3000:3000 -e PORT=3000 abhi-ludo-server
```

---

## 📖 Documentation

Detailed architectural and design documents are available in the [`docs/`](docs/) directory:

- 📐 **[Architecture](docs/architecture.md):** Clean layer separation, Riverpod integration, and networking.
- 📜 **[Game Rules](docs/game-rules.md):** Formal definitions of captures, bonuses, and chaining.
- 🏆 **[Game Modes](docs/game-modes.md):** Deep dive into Classic vs Quick modes.
- 🎨 **[Branding & Design](docs/branding.md):** Color palette, typography, and accessibility markers.
- 🎲 **[Dice System](docs/dice-system.md):** Secure RNG entropy, distribution, and 3-sixes avoidance.
- ⚙️ **[Game Engine](docs/game-engine.md):** State machine, turn lifecycle, and immutable state.
- 📦 **[Asset Register](docs/ASSETS.md):** OFL font and CC0 audio licenses.
- 📝 **[Changelog](docs/changelog.md):** Phase-by-phase implementation log.
- 🧭 **[Roadmap](docs/requirements.md):** Phased requirements and future plans.

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting pull requests.

1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'feat: Add AmazingFeature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Abhishek Choudhary**
- GitHub: [@Abhishekchoudhary9622](https://github.com/Abhishekchoudhary9622)
- Repository: [Abhi-Ludo](https://github.com/Abhishekchoudhary9622/Abhi-Ludo)

<div align="center">
Made with ❤️ using Flutter, Dart & Node.js
</div>
