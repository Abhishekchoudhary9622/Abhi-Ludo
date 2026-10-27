import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dice_engine.dart';
import 'random_source.dart';

/// The single, app-wide dice RNG source.
///
/// Per docs/dice-system.md, local/offline play uses [SecureRandomSource]
/// everywhere (not a plain seedable `Random`), so there's one consistent,
/// defensible dice implementation rather than different RNGs for
/// "offline" vs future "online" modes.
final randomSourceProvider = Provider<RandomSource>((ref) => SecureRandomSource());

/// The single, app-wide [DiceEngine] instance.
///
/// This is a thin Riverpod adapter over a plain-Dart object (per
/// docs/architecture.md §2) — [DiceEngine] itself has no Flutter import
/// and can be constructed/exercised with no widget tree at all.
final diceEngineProvider = Provider<DiceEngine>(
  (ref) => DiceEngine(ref.watch(randomSourceProvider)),
);
