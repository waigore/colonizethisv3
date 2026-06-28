import 'package:test/test.dart';

import '../tool/check_orders_dedup_diplomatic_helpers.dart';
import '../tool/check_orders_dedup_map_clones.dart';

void main() {
  group('findInlinedDiplomaticRelationGuardViolations', () {
    test('flags inline relation?.atWar checks', () {
      const src = r'''
if (relation?.atWar == true) {
  return rejectDiplomaticSub('at war', treasury);
}
''';
      final violations = findInlinedDiplomaticRelationGuardViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/validators/diplomatic/establish_overture_validator.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });
  });

  group('findInlinedGreatPowerGuardViolations', () {
    test('flags inline Great Power rejection guards', () {
      const src = r'''
if (!isGreatPower(ctx.game, targetId)) {
  return rejectDiplomaticSub('not gp', treasury);
}
''';
      final violations = findInlinedGreatPowerGuardViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/validators/diplomatic/alliance_validator.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });
  });

  group('runCheckOrdersDedupDiplomaticHelpers', () {
    test('passes on current repo tree', () {
      expect(runCheckOrdersDedupDiplomaticHelpers('.'), 0);
    });
  });
}
