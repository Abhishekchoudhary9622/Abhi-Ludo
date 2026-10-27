# Game Rules & Tactics (Ludo King Parity)

This document describes the rules and mechanics as implemented in Pip Rally, matching modern production Ludo King gameplay.

---

## 1. Board & Geometry

- **52 Shared Ring Cells:** Symmetrical cross-shaped board layout with player entry points spaced 13 cells apart (`52 / 4`).
- **8 Safe Cells:**
  - 4 Player Starting Cells (marked with arrows).
  - 4 Star / Pip-Flower Cells (offset +8 from each entry point).
  - Safe cells provide 100% capture immunity. Multiple tokens of the same or different players can safely co-exist on safe cells.
- **Private Home Lanes:** 6 dedicated colored home cells per player leading into the center Home Triangle (progress 57).
- **Exact Finish:** Overshooting final home is prohibited; tokens require exact dice values to reach progress 57.

---

## 2. Game Modes

### Classic Mode
- **Starting State:** All 4 tokens begin in the yard (base).
- **Home Entrance:** Open freely without requiring a capture.
- **Win Condition:** First player to bring **all 4 tokens** to final home wins.

### Quick Mode
- **Starting State:** **2 tokens start already deployed** on the track at progress 0 (entry cell); 2 tokens remain in base.
- **Home Corridor Lock:** A player **MUST capture (kill) at least 1 opponent token** during the match before any of their tokens can enter the home lane (progress 51..57).
- **Win Condition:** First player to bring **1 token** to final home wins the match.

---

## 3. Dice Mechanics & Roll Chaining

- **Cryptographic Fairness:** Rolls are generated via `Random.secure()`.
- **Leaving Base:** Requires rolling a `6` to move a token from base to entry cell (progress 0).
- **Bonus Rolls (Extra Turns):**
  1. **Rolling a 6:** Awards an extra roll after moving.
  2. **Capturing an Opponent (Kill):** Capturing any opponent token immediately awards a bonus roll **AND resets consecutive 6s count**.
  3. **Reaching Final Home:** Moving a token to progress 57 immediately awards a bonus roll **AND resets consecutive 6s count**.
- **Tactical Turn Chaining & 3-Sixes Prevention:**
  - Tactical actions (Kill or Home Arrival) reset the consecutive-6 counter to 0, allowing sequences like `Roll 6 -> Roll 6 -> Kill Opponent -> Roll 6 again`.
  - If a player rolls two consecutive 6s *without* an intermediate kill or home arrival reset, the dice engine guarantees the 3rd roll is chosen uniformly from `1..5` (guaranteeing no frustrating 3rd six roll occurs, matching Ludo King's algorithm).

---

## 4. Capture & Stacking Tactics

- **Capture (Kill):** Landing on an ordinary (non-safe) ring cell occupied by a single opponent token captures it, returning it to their yard. The attacking player gains +1 kill count and a bonus roll.
- **Multi-Token Blocking:** If an opponent has 2 or more of their own tokens stacked together on a non-safe ring cell, that cell is blocked; no other player may land on it.
- **Safe Cell Coexistence:** Opponents sharing a star or starting safe cell cannot capture each other. Tokens are visually rendered in a neat multi-token cluster layout.

---

## 5. Player Seat Management & Pass-and-Play

- Supports 2, 3, or 4 local players.
- Inactive seats are seamlessly skipped by the turn engine.
- Colorblind accessibility: each player seat has a distinct geometric shape marker (Dot, Triangle, Square, Diamond) on tokens.
