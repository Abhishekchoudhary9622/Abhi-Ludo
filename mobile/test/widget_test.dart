import 'package:flutter_test/flutter_test.dart';
import 'package:abhi_ludo/game/dice/dice_engine.dart';
import 'package:abhi_ludo/game/dice/random_source.dart';

void main() {
  group('DiceEngine Tests', () {
    test('rolls values between 1 and 6 when allowSix is true', () {
      final engine = DiceEngine(SecureRandomSource());
      for (var i = 0; i < 100; i++) {
        final val = engine.roll(allowSix: true);
        expect(val, inInclusiveRange(1, 6));
      }
    });

    test('never rolls 6 when allowSix is false (3rd six prevention)', () {
      final engine = DiceEngine(SecureRandomSource());
      for (var i = 0; i < 100; i++) {
        final val = engine.roll(allowSix: false);
        expect(val, inInclusiveRange(1, 5));
        expect(val, isNot(equals(6)));
      }
    });
  });
}
