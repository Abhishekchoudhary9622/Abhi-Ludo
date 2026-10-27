# Assets

This file tracks every external asset actually integrated into the app, its source, license, and where it's used. **No asset is used until its license has been verified on this list.**

Per the branding/originality requirements, the game's signature visuals — logo, board, tokens, dice — are custom-built in Flutter (vector/`CustomPainter`), not sourced externally, so they carry no third-party license risk. External assets are limited to generic UI chrome, fonts, and sound effects.

## Status: shortlist only — nothing integrated yet

Nothing below is wired into the app yet. This is the shortlist to choose from once we reach the UI-polish (Phase 6) and audio (Phase 7) phases. Each row's license was checked against the source's own license page (linked), current as of Aug 2026.

### Fonts (near-certain picks — low risk, will confirm exact files at integration)

| Asset | Source | URL | Author | License | Attribution required | Where used |
|---|---|---|---|---|---|---|
| Fredoka (variable) | Google Fonts | https://fonts.google.com/specimen/Fredoka | Milena Brandão, Ben Nathan | SIL OFL 1.1 | No in-app credit required; keep OFL license file with the font | Headings, logo wordmark, big UI numbers |
| Nunito | Google Fonts | https://fonts.google.com/specimen/Nunito | Vernon Adams et al. | SIL OFL 1.1 | No in-app credit required; keep OFL license file with the font | Body text, buttons, labels |

### UI chrome candidates (generic buttons/icons/panels only — not the board/token/dice art)

| Asset | Source | URL | Author | License | Attribution required | Where used (if selected) |
|---|---|---|---|---|---|---|
| Board Game Icons | Kenney | https://kenney.nl/assets/board-game-icons | Kenney | CC0 (public domain, per kenney.nl/support) | No | Candidate for misc icons (e.g., settings, mute) if custom icons aren't enough |
| UI Pack | Kenney | https://kenney.nl/assets/ui-pack | Kenney | CC0 (public domain, per kenney.nl/support) | No | Candidate as a base reference for button/panel 9-slice shapes, restyled to our palette rather than used verbatim |

### Sound effect candidates (license verified per-file before any download)

| Asset | Source | URL | Author | License | Attribution required | Where used (if selected) |
|---|---|---|---|---|---|---|
| Dice roll.mp3 | Freesound | https://freesound.org/people/SciFiSounds/sounds/547928/ | SciFiSounds | To confirm exact tag on page at integration time (Freesound mixes CC0/CC-BY/CC-BY-SA per file) | TBD per confirmed tag | Dice roll SFX candidate |
| Rolling dice.wav | Freesound | https://freesound.org/people/Rach_Capache/sounds/366408/ | Rach_Capache | To confirm exact tag on page at integration time | TBD | Dice roll SFX candidate |
| Dice roll (SFX) | Pixabay | https://pixabay.com/sound-effects/search/dice%20rolling/ | Various Pixabay contributors | Pixabay Content License — free for commercial & non-commercial use, no attribution required (verified: https://pixabay.com/service/license-summary/) | No | Dice roll / button-press / victory SFX candidates |

### Explicitly NOT sourced externally (custom-built instead)

- Game logo — custom vector composition (Flutter widgets/`CustomPainter`).
- Board artwork — custom `CustomPainter`/widget rendering of the logical board (see architecture.md).
- Token artwork — custom vector shapes per player color/shape-marker.
- Dice artwork — custom `CustomPainter` cube + pip rendering.

## Process reminder

Before adding any row above as "integrated": re-open the exact asset page, confirm the license tag shown *on that specific asset* (not just the site's general policy), record the confirmed license + any required attribution text here, and only then copy the file into `mobile/assets/`.
