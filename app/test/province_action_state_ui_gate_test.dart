// Observe / canMutateViaUi gating for MAP20001 civilian inline actions
// (Refs #4752 AC6).

import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  const missingUnits = (
    showIcon: true,
    enabled: false,
    hasMatchingUnits: false,
  );

  test(
    'canMutateViaUi false hides civilian icons and preserves unit flags',
    () {
      final states = provinceOverlayInlineActions(
        explore: missingUnits,
        prospect: missingUnits,
        buildImprovement: missingUnits,
      );
      final gated = gateProvinceInlineActionsForUi(
        states: states,
        canMutateViaUi: false,
      );
      expect(gated.explore.showIcon, isFalse);
      expect(gated.explore.enabled, isFalse);
      expect(gated.explore.hasMatchingUnits, isFalse);
      expect(gated.prospect.showIcon, isFalse);
      expect(gated.buildImprovement.showIcon, isFalse);
    },
  );

  test('canMutateViaUi true leaves civilian icon visibility unchanged', () {
    final states = provinceOverlayInlineActions(explore: missingUnits);
    final gated = gateProvinceInlineActionsForUi(
      states: states,
      canMutateViaUi: true,
    );
    expect(gated.explore, missingUnits);
  });
}
