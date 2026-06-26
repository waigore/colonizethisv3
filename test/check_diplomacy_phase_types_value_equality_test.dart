import 'package:test/test.dart';

import '../tool/check_diplomacy_phase_types_value_equality.dart';

void main() {
  group('diplomacyPhaseTypesValueEqualityPathInScope', () {
    test('positive: phase_types value-type files are in scope', () {
      expect(
        diplomacyPhaseTypesValueEqualityPathInScope(
          'packages/colonizethis_diplomacy/lib/src/diplomacy/phase_types/'
          'overture_offer.dart',
        ),
        isTrue,
      );
      expect(
        diplomacyPhaseTypesValueEqualityPathInScope(
          'packages\\colonizethis_diplomacy\\lib\\src\\diplomacy\\phase_types'
          '\\ftp_offer.dart',
        ),
        isTrue,
      );
    });

    test('negative: the canonical mixin file itself is exempt', () {
      expect(
        diplomacyPhaseTypesValueEqualityPathInScope(
          'packages/colonizethis_diplomacy/lib/src/diplomacy/phase_types/'
          'value_equality.dart',
        ),
        isFalse,
      );
    });

    test('negative: non-phase_types and non-dart paths are out of scope', () {
      expect(
        diplomacyPhaseTypesValueEqualityPathInScope(
          'packages/colonizethis_diplomacy/lib/src/diplomacy/'
          'overture_resolver.dart',
        ),
        isFalse,
      );
      expect(
        diplomacyPhaseTypesValueEqualityPathInScope(
          'packages/colonizethis_diplomacy/lib/src/diplomacy/phase_types/'
          'README.md',
        ),
        isFalse,
      );
    });
  });

  group('diplomacyPhaseTypesValueEqualityViolationReason', () {
    test('positive: a hand-written operator == is flagged', () {
      const content = '''
class OvertureOffer {
  const OvertureOffer(this.id);
  final String id;

  @override
  bool operator ==(Object other) =>
      other is OvertureOffer && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
''';
      final reason = diplomacyPhaseTypesValueEqualityViolationReason(content);
      expect(reason, isNotNull);
      expect(reason, contains(diplomacyValueEqualityMixinName));
    });

    test('negative: mixing in ValueEquality is allowed', () {
      const content = '''
import 'value_equality.dart';

class OvertureOffer with ValueEquality {
  const OvertureOffer(this.id);
  final String id;

  @override
  List<Object?> get equalityFields => [id];
}
''';
      expect(
        diplomacyPhaseTypesValueEqualityViolationReason(content),
        isNull,
      );
    });
  });

  group('runCheckDiplomacyPhaseTypesValueEquality', () {
    test('passes on the current repo tree', () {
      expect(runCheckDiplomacyPhaseTypesValueEquality('.'), 0);
    });
  });
}
