# Branding

Status: **Proposed — awaiting your final pick before Phase 1 art work begins.**

## Naming process

Search method used: general web search + Google Play / App Store listing search for exact and close name matches (not a formal trademark registry search). No exact collisions with a Ludo-style board game were found for the shortlisted names below. This is a lightweight clearance, not legal confirmation — **run a real trademark search (e.g., USPTO TESS, or your local equivalent) before any public/commercial launch.**

### 5 name concepts

1. **Pip Rally** — "pip" (a dice/token dot, and slang for something small-but-mighty) + "rally" (racing home). Reads as an energetic race game, doesn't echo "Ludo" wording at all.
2. **Fourpath** — literal and descriptive (4 players, 4 paths converging home). Strong for App Store search discoverability, weaker as a distinctive brand mark.
3. **Dicewind** — "dice" + "wind" (motion, journey). Short, a little abstract, no collisions found.
4. **Trackfour** — evokes the four player tracks converging at the center. Simple, slightly generic-sounding.
5. **Pipwise** — playful, implies cleverness/strategy. Short and brandable; least literally descriptive of the five.

### Recommendation

**Pip Rally.** Reasoning:
- Distinct from "Ludo" in sound and spelling, no partial-name collisions surfaced in search.
- "Pip" gives a natural visual hook for the logo (see below) and ties directly to dice pips and token dots — useful across icon, loading spinner, and marketing.
- "Rally" communicates energy/competition without borrowing any existing board-game's specific terminology.
- Reads well as both an app name and an in-game voice ("Time for a Pip Rally!").

I'll proceed with **Pip Rally** for the rest of this document and for Phase 1 scaffolding, but this is easy to rename later (it's just a display name + a few constants) if you'd rather pick one of the other four or suggest your own.

## Visual identity (for "Pip Rally")

### Color palette

| Role | Color | Hex |
|---|---|---|
| Board base / background | Warm parchment | `#F5EFE0` |
| Ink / primary text / board lines | Deep charcoal navy | `#1F2640` |
| Player 1 | Coral red | `#FF5A5F` |
| Player 2 | Teal green | `#2EC4B6` |
| Player 3 | Sunflower gold | `#FFC94D` |
| Player 4 | Cobalt blue | `#3A6EA5` |
| Primary CTA / accent | Deep amber | `#FF8A3D` |
| Surface / cards | Soft off-white | `#FFFBF3` |

Four clearly-distinguishable player hues are practically required for a Ludo-style board (colorblind players need to tell 4 sets of tokens apart), which is why the chosen hues sit in a similar red/green/yellow/blue family to classic Ludo — but the exact shades, the overall palette, and the token/board rendering are original, not copied from any existing app. As an original accessibility touch, tokens will also carry a distinct **shape marker** (dot / triangle / square / diamond) per player in addition to color, so colorblind players aren't relying on hue alone.

### Typography

- Headings / logo / big UI numbers: **Fredoka** (Google Fonts, SIL OFL 1.1) — rounded, playful, reads clearly at large sizes.
- Body / buttons / secondary text: **Nunito** (Google Fonts, SIL OFL 1.1) — clean, rounded-adjacent, highly legible at small sizes.

Both are open-source under OFL: free to use/bundle in the app; the license just needs to travel with the font files (a `LICENSE.txt`/OFL notice in the assets folder), no in-app attribution UI is required.

### Visual style

"Soft papercraft" look: flat colors, rounded rectangle cells, subtle drop shadows for elevation instead of heavy gradients or 3D bevels. Consistent 8px spacing grid across UI.

### Board style

Classic cross-shaped Ludo path layout (this cell arrangement is generic board-game geometry, not anyone's copyrighted artwork) rendered with the original palette above:
- Rounded-corner cells instead of sharp squares.
- Each player's home lane tinted in their color.
- Safe cells marked with a small original "pip-flower" glyph (a 4-petal dot cluster) instead of the star icon common to existing Ludo apps.

### Token style

Rounded "pawn" silhouette (not a mimic of any specific commercial app's token shape), flat-colored per player, with the shape-marker glyph mentioned above for accessibility. No faces/eyes (keeps it clean and avoids resembling any specific existing character-token design).

### Dice style

Custom-drawn rounded cube with pips drawn as simple filled circles via Flutter `CustomPainter` (no 3D dice asset). Roll animation is a bounce/squash-and-stretch + pip-shuffle rather than a 3D tumble, which keeps it original and computationally cheap.

### UI style

Rounded card-based panels, large touch targets (48dp minimum), soft elevation shadows, generous spacing, a single accent color (amber) reserved for primary actions so it stays visually calm rather than "busy."

### Logo concept

Wordmark "Pip Rally" set in Fredoka Bold. The dot of the lowercase "i" in "Pip" is replaced by a tiny cluster of 4 small colored dots (one per player color) — a small original mark that visually encodes "4 players, 4 tokens" without resembling any existing Ludo app's icon. Fully buildable as a vector/text composition inside Flutter — no external logo asset needed.

## Where this is used

This palette/typography/style will be centralized in a single Flutter theme/design-tokens file during Phase 1, so screens consume named colors/text styles rather than hardcoded hex values scattered across widgets.
