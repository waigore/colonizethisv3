import 'package:colonizethis_diplomacy/src/diplomacy/phase_types/value_equality.dart';
import 'package:colonizethis_test/test.dart';

/// Direct coverage for the shared [ValueEquality] mixin that backs the
/// Diplomacy-phase Offer/Decision/Prompt/Pending value types (Refs #3715).
void main() {
  group('ValueEquality', () {
    test('positive: same fields are equal and share a hashCode', () {
      const a = _Pair('x', 1);
      const b = _Pair('x', 1);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(identical(a, a), isTrue);
    });

    test('negative: a differing field breaks equality', () {
      const a = _Pair('x', 1);
      expect(a, isNot(const _Pair('x', 2)));
      expect(a, isNot(const _Pair('y', 1)));
    });

    test('negative: a different runtime type is never equal', () {
      // Same field values but a distinct concrete type must not be equal,
      // matching the prior `other is <Type>` guards.
      expect(const _Pair('x', 1), isNot(equals(const _OtherPair('x', 1))));
    });

    test('negative: null vs non-null fields are distinguished', () {
      expect(const _Nullable(null), isNot(const _Nullable('v')));
      expect(const _Nullable(null), equals(const _Nullable(null)));
    });
  });
}

class _Pair with ValueEquality {
  const _Pair(this.name, this.count);

  final String name;
  final int count;

  @override
  List<Object?> get equalityFields => [name, count];
}

class _OtherPair with ValueEquality {
  const _OtherPair(this.name, this.count);

  final String name;
  final int count;

  @override
  List<Object?> get equalityFields => [name, count];
}

class _Nullable with ValueEquality {
  const _Nullable(this.value);

  final String? value;

  @override
  List<Object?> get equalityFields => [value];
}
