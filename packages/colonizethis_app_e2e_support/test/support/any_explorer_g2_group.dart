library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'any_explorer_assign_fleet_harness.dart';

void registerAnyExplorerG2Group() {
  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — panel sweep true branches',
    () {
      testWidgets('single Assign row with enabled Explore tile -> true', (
        tester,
      ) async {
        var assignTaps = 0;
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
          reason: 'The canonical happy path: one Assign row whose '
              'pushed sheet exposes an enabled `Explore` tile must '
              'return true after exactly one tap.',
        );
      });

      testWidgets(
        'second Assign row carries the enabled Explore tile -> true after '
        'two taps',
        (tester) async {
          var firstTaps = 0;
          var secondTaps = 0;
          await tester.pumpWidget(
            wrap(
              civilianPanel(
                children: [
                  AssignRow(
                    label: kUnitTypeBuilder,
                    exploreTileEnabled: false,
                    onTap: () => firstTaps++,
                  ),
                  AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: true,
                    onTap: () => secondTaps++,
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
            firstTaps,
            1,
            reason: 'A disabled `Explore` tile on the first row must NOT '
                'short-circuit to `true`; the helper has to keep walking '
                'until it finds an `enabled: true` Explore tile.',
          );
          expect(
            secondTaps,
            1,
            reason: 'The second row carrying the enabled `Explore` tile '
                'is the first true match — pin the linear sweep order so '
                'a regression that reorders / skips rows fails here.',
          );
        },
      );
    },
  );

}
