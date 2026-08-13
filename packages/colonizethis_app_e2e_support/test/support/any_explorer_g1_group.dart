library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'any_explorer_assign_fleet_harness.dart';

void registerAnyExplorerG1Group() {
  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — snapshot short-circuit',
    () {
      testWidgets('snapshot says Explore enabled -> true (no panel sweep)', (
        tester,
      ) async {
        var assignTaps = 0;
        ctE2eCivilianPanelSnapshot = snapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
        await tester.pumpWidget(
          wrap(
            civilianPanel(
              children: [
                AssignRow(
                  label: kUnitTypeExplorer,
                  exploreTileEnabled: true,
                  onTap: () => assignTaps++,
                ),
              ],
            ),
          ),
        );
        expect(
          await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
          isTrue,
        );
        expect(
          assignTaps,
          0,
          reason: 'The snapshot short-circuit must return immediately '
              'without tapping any Assign row; a regression that walked '
              'the panel anyway would inflate every fleet-reach turn by '
              'the slow-path budget (Bottleneck 5).',
        );
      });

      testWidgets(
        'snapshot says no Explore enabled -> false (no panel sweep)',
        (tester) async {
          var assignTaps = 0;
          ctE2eCivilianPanelSnapshot = snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad],
            },
          );
          await tester.pumpWidget(
            wrap(
              civilianPanel(
                children: [
                  AssignRow(
                    label: kUnitTypeBuilder,
                    exploreTileEnabled: true,
                    onTap: () => assignTaps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
            isFalse,
          );
          expect(
            assignTaps,
            0,
            reason: 'The snapshot `false` verdict is contractually distinct '
                'from `null` and must short-circuit the panel sweep too. '
                'Conflating `false` with `null` would surface a false '
                'positive whenever the snapshot already proved no Explore '
                'is assignable.',
          );
        },
      );

      testWidgets(
        'snapshot null -> falls through to panel sweep (tap occurs)',
        (tester) async {
          var assignTaps = 0;
          ctE2eCivilianPanelSnapshot = null;
          await tester.pumpWidget(
            wrap(
              civilianPanel(
                children: [
                  AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: true,
                    onTap: () => assignTaps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
            isTrue,
          );
          expect(
            assignTaps,
            1,
            reason: 'A null snapshot is the "no plumbing this turn" '
                'state — the helper must fall through to the live '
                'Assign-row walk rather than treat null as a definitive '
                'verdict (matching the documented `bool?` contract of '
                '[e2eExploreAssignEnabledFromCivilianSnapshot]).',
          );
        },
      );
    },
  );

}
