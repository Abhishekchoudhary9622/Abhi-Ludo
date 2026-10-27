# Research Notes

This document records the technical research behind the architecture decisions for this project. It is a living document — update it whenever a new technical decision is made, and note the date/source.

## 1. Flutter / State Management

**Decision: Riverpod (`flutter_riverpod` 3.x)**

- Flutter's own docs present state management as a spectrum of options, not a single mandated choice: https://docs.flutter.dev/data-and-backend/state-mgmt/options
- Considered: `provider`, `flutter_riverpod`, `flutter_bloc`, `GetX`.
- Riverpod 3.0 shipped September 2025; current stable line is 3.3.x (per pub.dev / riverpod.dev, checked Aug 2026). Source: https://riverpod.dev , https://pub.dev/packages/flutter_riverpod
- Why Riverpod over the alternatives for *this* project specifically:
  - The game engine (board/dice/turn/movement/capture/win rules) must be usable **without any Flutter widget or `BuildContext`** (hard requirement). Riverpod providers/notifiers are plain Dart objects that can be read and tested via a `ProviderContainer` with zero widget tree involved — the engine stays framework-agnostic and the notifier is just a thin adapter.
  - Compile-time provider safety catches wiring mistakes (wrong provider type, disposed reads) at build/analyze time instead of at runtime — valuable for a rules-heavy app where a silent bug means an invalid game state.
  - Lower boilerplate than Bloc's event/state class pairs for a project with one dev/small team and a hard "no huge testing infra" directive — Bloc's ceremony pays off mainly for large teams enforcing strict event sourcing, which isn't a stated requirement here.
  - `provider` (the plain package, not Riverpod) is effectively superseded by Riverpod for new projects; several current sources describe Provider as the InheritedWidget-based predecessor Riverpod fixed shortcomings of.
  - `GetX` was rejected: it relies on a global service-locator pattern and lacks the compile-time safety Riverpod provides; several current comparisons note serious production teams have moved away from it.
  - Sources (checked Aug 2026): https://docs.flutter.dev/data-and-backend/state-mgmt/options , https://riverpod.dev/ , comparative articles cross-checked across dev.to / startdebugging.net / foresightmobile.com (treated as secondary opinion, not authoritative — Flutter's own docs page and riverpod.dev are the primary sources).
- We will use plain `flutter_riverpod` + `riverpod` (no `hooks_riverpod`, no `riverpod_generator` codegen) to avoid an extra build_runner dependency for a project of this size. This can be revisited if boilerplate grows.

## 2. Dice / Randomness (Dart)

- `dart:math` exposes two RNG constructors: `Random()` (pseudo-random, not suitable for anything security-sensitive) and `Random.secure()` (cryptographically secure source; throws `UnsupportedError` only if the platform truly cannot provide secure entropy — not expected on Android/iOS/desktop). Source: https://api.dart.dev (dart-math library), mirrored at https://api.flutter.dev/flutter/dart-math/Random/Random.secure.html
- Decision: local/offline dice uses `Random.secure()` wrapped behind a `RandomSource` interface (see architecture.md) so it can be swapped/mocked, with a documented, non-silent fallback to `Random()` only if `Random.secure()` throws (extremely unlikely on Android).
- For online multiplayer (future phase), the **server** is authoritative and will generate the roll using Node's built-in `crypto` module (`crypto.randomInt(1, 7)`), never trusting a client-supplied value. This is standard Node.js API, no extra dependency needed.

## 3. Backend Stack

- **Node.js + Express + Socket.IO** confirmed as specified. Current Socket.IO stable is 4.8.x (checked via https://socket.io/docs/v4/client-installation/, Dec 2025 release note). Node.js 10+ is the documented minimum for Socket.IO v4 servers, but we will target an actively-supported Node LTS at implementation time.
- Dart client-side Socket.IO support: the community package `socket_io_client` (Dart port, maintained under `rikulo/socket.io-client-dart`) documents compatibility bands — its current major version line targets Socket.IO server v4.7–v4.x. We will pin an exact compatible version when the multiplayer phase starts and re-verify compatibility against whatever Socket.IO server version is installed at that time.
- No GraphQL/gRPC — plain REST (Express) for stateless requests (health check, auth callbacks, stats/leaderboard reads) and Socket.IO for realtime game events, matching the "avoid unnecessary complexity" directive.

## 4. Database

- **MongoDB Atlas free tier (M0)**: one free cluster per project, shared RAM/vCPU, connection limit capped at 500 connections, and M0/shared tiers throttle read/write ops per second. Sufficient for the stated 50–100 concurrent users / 20–30 concurrent rooms scale, since live game state will **not** live in MongoDB (it stays in server memory) — Mongo only receives persisted results after a match ends. Sources: https://www.mongodb.com/docs/atlas/reference/free-shared-limitations/ , https://www.mongodb.com/docs/atlas/reference/alert-resolutions/connection-alerts/
- Re-verify current M0 limits again right before the MongoDB integration phase, since free-tier terms can change.

## 5. Deployment (Render)

- Render's free web service tier: 512MB RAM / 0.1 CPU, spins down after 15 minutes with no inbound traffic (HTTP or WebSocket), spin-up takes ~1 minute on the next request. As of the April 23, 2026 pricing overhaul, Render moved to flat workspace pricing (Hobby plan still $0) with free-tier bandwidth reduced to 5GB/month and ~750 free instance-hours/month per workspace. Sources: https://render.com/free , https://render.com/docs/new-workspace-plans , https://render.com/blog/free-tier (cross-checked against secondary sources for the 2026 pricing change).
- Implication for this project: free tier is fine for development/demo, but the "spin down after 15 min" behavior means a WebSocket-based multiplayer game will feel laggy on first connect after idle. This should be flagged to the user again at the deployment phase — a paid "Starter" instance (~$7/mo at time of research) avoids spin-down if budget allows later; not required for initial development.
- Render requires binding to `process.env.PORT`, supports WebSockets natively on web services, and expects the app not to depend on a persistent local filesystem (ephemeral disk) — confirmed via Render's own docs, to be re-read in full at the deployment phase.

## 6. Android Build

- Flutter's official Android deployment guide: https://docs.flutter.dev/deployment/android — `flutter build appbundle` is the standard release artifact for Play Store; `flutter build apk` for direct/manual installs. Default `minSdkVersion` in modern Flutter templates is governed by the Flutter Gradle plugin defaults, not hardcoded — will be checked against current Flutter stable at Phase 1 project creation time rather than assumed.

## 7. Asset Source Research

Sources evaluated for free/legal assets (see `docs/ASSETS.md` for the concrete shortlist and per-asset license records):

- **Kenney (kenney.nl)** — all packs are explicitly public-domain/CC0 per Kenney's own support page ("Yes, all game assets on the asset pages are public domain licensed (CC0)."). Good candidate for generic UI chrome (buttons/panels/icons), not for the game's signature art (board/tokens/dice/logo), which will be custom per the originality requirement.
- **OpenGameArt.org** — hosts mixed licenses (CC0, CC-BY, CC-BY-SA, GPL) *per individual submission*; every asset page must be checked individually before use, no blanket assumption.
- **itch.io free asset packs** — mixed licenses per creator; several CC0 board-game-piece packs exist (e.g., Chequered Ink's broad commercial-use grant, RhosGFX's CC0 vector chess pieces) but again licensed per-listing.
- **Pixabay** — Content License allows free commercial and non-commercial use with no attribution required, except content depicting recognizable trademarks/logos/people (irrelevant for our SFX use case). Verified via https://pixabay.com/service/license-summary/ and https://pixabay.com/service/faq/.
- **Freesound.org** — hosts CC0 and various CC-BY/CC-BY-SA/GPL sounds *per file*; we will only select CC0-tagged sounds to avoid attribution-tracking overhead, verified per-file at integration time.
- **Google Fonts** — all fonts are open source (mostly OFL 1.1, some Apache 2.0); confirmed via each font's own license page at integration time.

## 8. Open Questions to Revisit Later

- Exact Node LTS version and Socket.IO server version to pin — check immediately before Phase 9 (backend init).
- Exact `socket_io_client` Dart package version compatible with the pinned server version — check immediately before Phase 9/10.
- Google OAuth current setup flow (client IDs, consent screen requirements) — research fully at Phase 13, not before.
- Formal trademark clearance for the chosen game name — only basic app-store/web searches have been done so far (see branding.md); a real trademark registry check is recommended before any public commercial launch.
