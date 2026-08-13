library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'any_explorer_assign_fleet_harness.dart';

void registerAnyExplorerG4Group() {
  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — dedup and bounds',
    () {
      testWidgets(
        'visited Assign widgets are deduped across sweep steps '
        '(same widget identity not tapped twice)',
        (tester) async {
          var taps = 0;
          await tester.pumpWidget(
            wrap(
              civilianPanel(
                children: [
                  AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: false,
                    onTap: () => taps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(
              tester,
              maxPanelSweepSteps: 4,
            ),
            isFalse,
          );
          expect(
            taps,
            1,
            reason: 'Across 4 sweep steps the same Assign widget must be '
                'tapped at most once — the identityHashCode-deduped '
                '`visitedAssignWidgets` set guards against re-tapping a '
                'stable row when the drag does not reveal new rows. A '
                'regression that dropped the dedup would inflate the '
                'sweep by 4× on every fleet-reach retry.',
          );
        },
      );

      testWidgets(
        'maxPanelSweepSteps = 0 short-circuits before any Assign tap',
        (tester) async {
          var taps = 0;
          await tester.pumpWidget(
            wrap(
              civilianPanel(
                children: [
                  AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: true,
                    onTap: () => taps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(
              tester,
              maxPanelSweepSteps: 0,
            ),
            isFalse,
          );
          expect(
            taps,
            0,
            reason: 'A `maxPanelSweepSteps: 0` ceiling must enter the '
                'for-loop zero times and return false before any tap — '
                'pins the bound as the canonical kill-switch the issue '
                '§ Bottleneck 5 narrowed from 24 to 16.',
          );
        },
      );
    },
  );

}
