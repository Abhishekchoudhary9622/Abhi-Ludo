# Project Overview — Pip Rally

Pip Rally is a production-grade Ludo-style board game for Android, built with Flutter/Dart on the client and Node.js/Express/Socket.IO/MongoDB Atlas on the backend (backend added once local gameplay is complete).

---

## What this is

- A 2–4 player, 4-tokens-per-player racing/capture board game with **Ludo King parity** mechanics and an original visual identity ("soft papercraft" aesthetic).
- Two complete modes:
  - **Classic Mode:** Traditional 4-token race with full board traversal and free home entrance.
  - **Quick Mode:** Fast-paced match where 2 tokens start deployed, 1 token home wins, and **a capture is strictly required to unlock the home corridor**.
- **Tactical Chaining:** Bonus rolls on rolling a 6, capturing an opponent, or finishing a pawn, with tactical consecutive-6 resets and 3rd six cap in RNG.
- **Dynamic Board Graphics:** 100% vector-based `CustomPainter` rendering with multi-token sub-grid clustering on safe cells.
- **Audio Feedback:** Sound effects for rolls, token hops, captures, and turn changes via `AudioService`.
- Playable **fully offline** with pass-and-play local multiplayer.

---

## Documentation Map

| Doc | Purpose |
|---|---|
| `docs/research.md` | Technical research backing major decisions (state mgmt, RNG, backend, DB, deployment, assets) |
| `docs/architecture.md` | Full system architecture: project structure, engine/UI separation, state management, server-authoritative design |
| `docs/branding.md` | Game name, palette, typography, visual identity, and accessibility markers |
| `docs/board-system.md` | Logical board model: cells, paths, safe cells, home lanes |
| `docs/game-engine.md` | Engine internals: GameState/PlayerState/TokenState/rules, event flow |
| `docs/dice-system.md` | DiceEngine design, RNG choice, 3-sixes avoidance |
| `docs/game-modes.md` | Classic Mode vs Quick Mode specifications |
| `docs/game-rules.md` | Exact rules and tactical mechanics as implemented |
| `docs/ASSETS.md` | External fonts (OFL) and audio assets (CC0) register |
| `docs/changelog.md` | Dated log of what was actually built, phase by phase |
| `docs/requirements.md` | Phased roadmap and future milestones |

---

## Current Status

**Phases 0 through 6 complete.** The app is a complete, production-grade local multiplayer game featuring Classic & Quick modes, cryptographic dice with 3-sixes prevention, turn chaining resets, multi-token cluster layout, auto-move QoL, full UI flow, and sound effects.
