# Abhi Ludo — Mobile Application Client 📱

The official mobile client for **Abhi Ludo**, built with **Flutter**, **Dart**, and **Riverpod** state management.

---

## 🌟 Highlights

- **Pure Dart Game Engine:** Completely separated from Flutter UI widgets (`lib/game/`), ensuring testability and modularity.
- **True Ludo King Parity:** Classic & Quick modes, turn chaining, tactical 3rd six cap, safe cells, and multi-token cluster layouts.
- **Smart AI Bots:** Heuristic utility-scoring bot engine (`lib/game/ai/bot_controller.dart`) for offline practice.
- **Vector-Rendered Visuals:** 100% custom `CustomPainter` board, tokens, and animated dice.
- **Audio & Haptics:** Low-latency sound effects powered by `audioplayers` with OFL/CC0 licensed audio.
- **Persistent Career Profiles:** Track matches, victories, win percentage, and total kills using `shared_preferences`.
- **Real-Time Multiplayer:** Built-in Socket.IO client (`lib/networking/socket_service.dart`) with room code lobby.

---

## 🛠 Getting Started

### Prerequisites
- Flutter SDK (3.13.1 or higher)
- Android SDK (API level 21+) or connected Android device / emulator

### Setup & Run

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis
flutter analyze

# 3. Run unit & engine tests
flutter test

# 4. Run on connected device
flutter run

# 5. Build release APK
flutter build apk --release
```

---

## 📂 Architecture & Directory Structure

```
mobile/
├── assets/
│   ├── audio/              # Sound effects (rolls, captures, pawn hops, victory)
│   ├── fonts/              # Fredoka & Nunito variable fonts (OFL licensed)
│   └── images/             # Profile avatars and game branding assets
├── lib/
│   ├── config/             # Theme tokens, palette, accessibility markers
│   ├── core/
│   │   ├── audio/          # AudioService SFX sound controller
│   │   └── stats/          # StatsRepository local career persistence
│   ├── features/           # UI Screens & Presentation layer
│   │   ├── game/           # In-game screen, CustomPainter board, animated dice
│   │   ├── home/           # Splash screen, Main menu, Mode & Player selection
│   │   ├── online/         # Online lobby, Room creation, Join dialog
│   │   ├── profile/        # Player career profile & stats view
│   │   └── settings/       # Settings & Rulebook modal
│   ├── game/               # PURE DART GAME ENGINE (No UI imports)
│   │   ├── ai/             # Smart Bot heuristic controller
│   │   ├── board/          # Logical coordinates, cells, star positions, paths
│   │   ├── dice/           # Fair RNG & 3-sixes avoidance logic
│   │   ├── engine/         # GameEngine state machine & Riverpod providers
│   │   └── rules/          # Movement, capture, chaining, and win rules
│   ├── networking/         # Socket.IO client service
│   └── main.dart           # App entry point & font license registration
└── test/
    └── widget_test.dart    # Test suite for engine & components
```

---

## 📄 License & Attribution

- Code is licensed under the [MIT License](../LICENSE).
- Bundled fonts (**Fredoka**, **Nunito**) are licensed under the SIL Open Font License (OFL).
- Audio assets are public domain (CC0) or royalty-free. See [`docs/ASSETS.md`](../docs/ASSETS.md).
