import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('AiValidationException', () {
    test('is typed as AI domain exception', () {
      final ex = AiValidationException('ai invariant failed');
      expect(ex, isA<AiDomainException>());
      expect(ex, isA<ArgumentError>());
      expect(ex.message, 'ai invariant failed');
    });

    test('value constructor preserves value and field name', () {
      final ex = AiValidationException.value(-1, 'threatScore', 'out of range');
      expect(ex, isA<AiDomainException>());
      expect(ex.invalidValue, -1);
      expect(ex.name, 'threatScore');
      expect(ex.message, 'out of range');
    });
  });
}
