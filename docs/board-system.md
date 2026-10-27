# Board System (Logical Board)

The logical board is a pure-Dart model under `lib/game/board/` with **no visual/screen-coordinate information at all**. The Flutter board widget (built in Phase 5) renders this model; it never the other way around.

## Design goals (per section 12/13)

- Every token position is a value the engine can reason about (compare, validate, serialize) without any knowledge of pixels.
- The engine can answer: where is this token, what's the next cell, how far has it traveled, is a move legal, has it entered its home lane, can it reach final home exactly, which opponents share this cell.
- No hardcoded per-player movement logic scattered through UI — one central board configuration drives all four players' paths.

## Model

### Cell identity

Every square on the board (including the 4 base "yards" and the 4 home lanes) has a stable, serializable `CellId`. Two categories of cell:

- **Ring cells**: the 52 shared cells that form the outer track all players' tokens travel along (standard Ludo-style board topology — this is generic board-game geometry, not anyone's copyrighted layout/art). Identified by a single absolute index `0..51` around the ring.
- **Home-lane cells**: each player has their own private 6-cell "run-in" lane (not shared with other players) plus a single `finalHome` cell. Identified by `(ownerPlayerId, laneIndex 0..5)` and a distinct `finalHome(ownerPlayerId)`.

Bases (where a player's tokens sit before rolling a six) are represented as a `TokenPosition.base` state per token rather than as board cells at all — a token in base occupies no ring/lane cell.

### Per-player path

Rather than four separate hardcoded path arrays maintained by hand, the path is generated from one shared configuration:

- `BoardConfig` defines: ring size (52), each player's **entry index** into the ring (the ring cell a token lands on when it first leaves base), each player's **home-lane entry index** (the ring cell just before turning into their private lane), lane length (6), and the set of ring indices that are **safe cells**.
- `PlayerPath.forPlayer(playerId, config)` derives that player's full logical path as an ordered list of `CellId`s: starting at their entry index, walking 51 ring cells around (wrapping via modulo), then transitioning into their own 6 home-lane cells, then `finalHome`. This derivation is table-driven from `BoardConfig`, so there is exactly one implementation of "how a path is built," reused for all 4 players by passing a different entry offset — not four copy-pasted, hand-tuned paths.
- A token's **movement progress** is a single integer: steps taken along *its own* `PlayerPath`, from `0` (just left base, standing on its entry cell) to `57` (51 ring steps + 6 lane steps = final home). This single number is what "how far has the token traveled" resolves to, and it's what a dice roll increments — the engine never needs to reason in raw ring indices once a token has an owner.

### Answering the required questions

| Question | How it's answered |
|---|---|
| Where is this token? | `token.progress` (0 = base marker aside, 1..57 along its `PlayerPath`) mapped through `PlayerPath.cellAt(progress)` → a `CellId` |
| What cell comes next? | `PlayerPath.cellAt(progress + 1)` |
| How far has it traveled? | `token.progress` directly |
| Is this movement legal? | `MovementRules` (see game-engine.md) checks: token not finished, `progress + diceValue <= 57`, and (if not yet out of base) the roll is a 6 |
| Has it entered home lane? | `progress > 51` |
| Can it reach final home? | `progress + diceValue == 57` exactly (overshoot is illegal — "exact movement into final home," section 1) |
| Which opponents are on this cell? | Board maintains a `Map<CellId, List<TokenId>>` occupancy index, rebuilt from current token positions each time state changes; a lookup by the *absolute ring* `CellId` naturally reveals opponents sharing that ring cell (home-lane cells are never shared across players by construction, since each player's lane cells carry their own `ownerPlayerId`) |

### Safe cells

Defined as a fixed set of ring indices in `BoardConfig` (each player's entry cell is conventionally safe, plus a small number of additional star-marked cells spaced around the ring — exact indices finalized and documented in `docs/game-rules.md` once Phase 4 implements capture rules). Safe cells are a board-level fact (`BoardConfig.isSafe(ringIndex)`), consumed by `CaptureRules`, not duplicated as a separate lookup elsewhere.

## Why this separation matters (restating section 12)

Because the entire path/occupancy model is expressed in `CellId`/`progress` integers with zero pixel knowledge, the same model can be:
- Reused unchanged by a Node.js/JS reimplementation on the server (same *logic*, ported deliberately, verified against `docs/game-rules.md`) for server-authoritative multiplayer.
- Unit-exercised via a debug screen with plain text output, before any board widget exists (Phases 1–4).
- Rendered by more than one visual board skin later (e.g. a future board theme) without touching any rule.
