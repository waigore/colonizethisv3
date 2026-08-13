library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'any_explorer_assign_fleet_harness.dart';

void registerAnyExplorerG3Group() {
  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — panel sweep false branches',
    () {
      testWidgets('no Assign rows at all -> false (sweep exhausted)', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(
            civilianPanel(
              children: const [ListTile(title: Text('No Assign here'))],
            ),
          ),
        );
        expect(
          await e2eAnyExplorerHasEnabledExploreAssignFleet(
            tester,
            maxPanelSweepSteps: 2,
          ),
          isFalse,
        );
      });

      testWidgets('only Assign rows whose sheet has no Explore tile -> false',
          (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          wrap(
            civilianPanel(
              children: [
                AssignRow(
                  label: kUnitTypeBuilder,
                  exploreTileEnabled: null,
                  onTap: () => taps++,
                ),
              ],
            ),
          ),
        );
        expect(
          await e2eAnyExplorerHasEnabledExploreAssignFleet(
            tester,
            maxPanelSweepSteps: 1,
          ),
          isFalse,
        );
        expect(
          taps,
          1,
          reason: 'When the assign sheet mounts but contains no `Explore` '
              'tile at all, the helper must pop the route and continue '
              'the sweep (returning false only after the sweep cap). A '
              'regression that returned true here would conflate '
              '"no Explore tile" with "Explore enabled".',
        );
      });

      testWidgets(
        'Assign row whose Explore tile is `enabled: false` -> false '
        '(panel-mounted but no readiness)',
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
              maxPanelSweepSteps: 1,
            ),
            isFalse,
          );
          expect(
            taps,
            1,
            reason: 'A disabled `Explore` tile is the canonical "panel '
                'mounted but Explore not assignable yet" state — the '
                'helper must check `enabled` strictly and continue past '
                '`enabled: false`. A regression that ignored the flag '
                'and returned true on tile-presence alone would mask '
                'real bundled-Explore readiness regressions on Linux CI.',
          );
        },
      );
    },
  );

}
