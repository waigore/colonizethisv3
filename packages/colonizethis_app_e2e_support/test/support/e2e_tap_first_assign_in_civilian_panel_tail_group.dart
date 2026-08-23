// Extracted from e2e_tap_first_assign_in_civilian_panel_test.dart (#4598 Slice C).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeBuilder, kUnitTypeMerchant;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

void registerE2eTapFirstAssignInCivilianPanelTailGroup() {
  testWidgets(
    'fails with TestFailure when the post-tap work menu never surfaces',
    (WidgetTester tester) async {
      // The Assign tap fires (host sees the press) but the synthetic
      // host is configured NOT to emit `Build improvement` / `Prospect` /
      // `Explore`. The helper's downstream `e2eWaitUntilAnyFinderHitTestable`
      // must run to its 5s timeout and surface a TestFailure rather than
      // returning silently.
      await tester.pumpWidget(
        _CustomCivilianPanelHost(
          showWorkMenuOnTap: false,
          bodyBuilder: (onAssign) => ListView(
            children: <Widget>[
              ListTile(
                title: const Text(kUnitTypeBuilder),
                trailing: TextButton(
                  onPressed: onAssign,
                  child: const Text('Assign'),
                ),
              ),
            ],
          ),
        ),
      );

      Object? caught;
      try {
        await e2eTapFirstAssignInCivilianPanel(tester);
      } catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'When the work menu never surfaces, the helper must throw '
            'TestFailure (via e2eWaitUntilAnyFinderHitTestable) so the '
            'caller fails the scenario at the offending turn rather than '
            'continuing with a stale civilian panel state.',
      );
    },
  );
}
