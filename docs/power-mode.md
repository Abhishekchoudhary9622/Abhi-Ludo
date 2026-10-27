# Power Mode Design

Status: **Proposed — Shield Guard recommended, awaiting your confirmation before implementation (Phase 8).**

Classic Mode must remain byte-for-byte unaffected by anything in this document. Power Mode is implemented as an additive rule layer injected into the shared game engine (see architecture.md, "Rule injection" section) — Classic Mode runs with a `ClassicRuleSet` whose power-hooks are no-ops, so the code path for Classic never executes Power logic at all.

## Concepts considered

### 1. Shield Guard — **recommended**

- **What it does:** each token gets exactly one single-use Shield for the whole match. While a token's Shield is active, it cannot be captured.
- **When it triggers:** the owning player chooses to activate a token's Shield as a free action on their turn, before rolling or before moving (a simple tap on their own token that still has its Shield available). It's consumed the moment it actually blocks a capture; if never triggered, it just sits unused as a safety net the player can time strategically.
- **How it affects gameplay:** adds a single, clearly-bounded resource-management decision ("when is my token most at risk, and is it worth using my one shield now?") without touching dice fairness or movement math at all.
- **Why it's balanced:** exactly one use per token (4 per player, never regenerates) caps the impact; it doesn't create snowballing advantages for whoever is already ahead, and it never blocks the *opponent's* dice/movement — it only nullifies one specific capture attempt.
- **How it interacts with existing rules:** the only integration point is the `CaptureRules` check — before applying a capture, check `token.shieldActive`; if true, consume the shield and skip the capture instead of sending the token to base. Movement, dice, turn, and win rules are completely untouched.

### 2. Momentum Boost

- **What it does:** immediately after a token captures an opponent, the capturing player gets one free bonus mini-roll (a d3, values 1–3) to move that same token further.
- **When it triggers:** automatically, right after a successful capture.
- **How it affects gameplay:** rewards aggressive play and can help a token escape danger right after capturing.
- **Why it's a weaker fit:** it snowballs — the player already capturing (often already ahead) gets extra progress, which cuts against "correct/fair game behavior" being the top priority and can make comebacks harder for a trailing player. Also touches the movement/roll pipeline in more places than Shield Guard does.

### 3. Swap Strike

- **What it does:** once per game, instead of moving, a player may swap the board positions of one of their own tokens with an eligible opponent token (not on a safe cell, not in a home lane).
- **When it triggers:** player-activated, once per match, replacing a normal move.
- **How it affects gameplay:** highly original and dramatic, but risky to balance — it can invalidate a token's home-lane progress in unintuitive ways and needs several extra edge-case rules (what if the opponent token is about to finish? what if both are in transit near their own home lane?).
- **Why it's a weaker fit for v1:** meaningfully higher implementation/testing surface for a "don't over-engineer, ship a correct v1" project. Worth keeping in mind as a *second* Power Mode mechanic in a later iteration, once Shield Guard is stable, since the modular rule-injection architecture supports adding it without touching Classic Mode or Shield Guard.

## Recommendation

Ship **Shield Guard** as the sole Power Mode mechanic for v1. It's the smallest, clearest, most balanced addition — one new resource, one new UI affordance (a shield icon/button on eligible tokens), one new check in the capture path. This matches the instruction to avoid piling on mechanics until the game becomes confusing, while still delivering a real, meaningful, original gameplay difference from Classic Mode.

Momentum Boost and Swap Strike are documented here as considered-but-deferred, not implemented, and not referenced anywhere else in the codebase until/unless you ask to add them.
