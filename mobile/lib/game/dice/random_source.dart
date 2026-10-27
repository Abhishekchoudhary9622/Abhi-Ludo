import 'dart:developer' as developer;
import 'dart:math';

/// Abstraction over "a source of random integers", so [DiceEngine] never
/// touches `dart:math` directly.
///
/// Per docs/dice-system.md, this exists specifically so a deterministic
/// fake can be substituted during manual debug-screen testing (e.g. to
/// force a run of 6's) without touching the production RNG code, without
/// needing a full automated test framework.
abstract class RandomSource {
  /// Returns a uniformly distributed integer in `[0, max)`.
  int nextInt(int max);
}

/// Cryptographically secure random source, backed by `Random.secure()`.
///
/// [Random.secure] is Dart's documented cryptographically-secure RNG
/// source. It only throws [UnsupportedError] if the platform genuinely
/// cannot supply secure entropy — not expected on Android. If that ever
/// happens, this class falls back to the plain, non-secure [Random] once,
/// and logs the fallback (never silently) so it's visible during manual
/// verification rather than hidden — see docs/dice-system.md.
class SecureRandomSource implements RandomSource {
  final Random _random;

  SecureRandomSource() : _random = _createSecureOrFallback();

  static Random _createSecureOrFallback() {
    try {
      return Random.secure();
    } catch (error) {
      developer.log(
        'Random.secure() unavailable, falling back to non-secure Random(). '
        'This should not happen on Android — investigate if seen.',
        name: 'SecureRandomSource',
        error: error,
        level: 900, // WARNING
      );
      return Random();
    }
  }

  @override
  int nextInt(int max) => _random.nextInt(max);
}
