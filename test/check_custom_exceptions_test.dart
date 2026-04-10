import 'package:test/test.dart';

import '../tool/check_custom_exceptions.dart';

void main() {
  group('findCustomExceptionViolations', () {
    test('flags throw ArgumentError()', () {
      const src = r'''
void f() {
  throw ArgumentError('x');
}
''';
      final v = findCustomExceptionViolations('packages/foo/lib/x.dart', src);
      expect(v, isNotEmpty);
      expect(v.first.exceptionType, 'ArgumentError');
      expect(v.first.line, greaterThan(0));
    });

    test('flags throw const ArgumentError()', () {
      const src = r'''
void f() {
  throw const ArgumentError('x');
}
''';
      final v = findCustomExceptionViolations('packages/foo/lib/x.dart', src);
      expect(v, isNotEmpty);
      expect(v.first.exceptionType, 'ArgumentError');
    });

    test('flags throw Exception()', () {
      const src = r'''
void f() {
  throw Exception('x');
}
''';
      final v = findCustomExceptionViolations('packages/foo/lib/x.dart', src);
      expect(v, isNotEmpty);
      expect(v.first.exceptionType, 'Exception');
    });

    test('flags throw ArgumentError.value(...)', () {
      const src = r'''
void f() {
  throw ArgumentError.value(1, 'a', 'b');
}
''';
      final v = findCustomExceptionViolations('packages/foo/lib/x.dart', src);
      expect(v, isNotEmpty);
      expect(v.first.exceptionType, 'ArgumentError.value');
    });

    test('allows domain validation throw', () {
      const src = r'''
void f() {
  throw ModelValidationException.value(1, 'a', 'b');
}
''';
      expect(
        findCustomExceptionViolations('packages/foo/lib/x.dart', src),
        isEmpty,
      );
    });

    test('skips test paths', () {
      const src = r'''
void f() {
  throw ArgumentError('x');
}
''';
      expect(
        findCustomExceptionViolations('packages/foo/test/x_test.dart', src),
        isEmpty,
      );
    });

    test('skips generated files', () {
      const src = r'''
void f() {
  throw ArgumentError('x');
}
''';
      expect(
        findCustomExceptionViolations('packages/foo/lib/x.g.dart', src),
        isEmpty,
      );
    });
  });
}
