import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_body.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_state.dart';

/// De-parted diplomacy-panel library seam checks (Refs #4117).
void main() {
  suppressLogsForTests();

  group('DiplomacyPanel modular split (Refs #4117)', () {
    test('constants, body widget, and panel are importable', () {
      expect(kDiplomacyRowNarrowMaxWidth, isNotNull);
      expect(DiplomacyPanelBody, isNotNull);
      expect(DiplomacyPanel.screenId, isNotEmpty);
      expect(DiplomacyAllianceBadge, isNotNull);
    });

    test('rows builder and power helpers are importable', () {
      expect(buildDiplomacyRows, isNotNull);
      expect(powerComparisonPercent(10, 5), 100);
      expect(diplomaticStandingChips, isNotNull);
    });
  });
}
