part of '../e2e_any_explorer_has_enabled_explore_assign_fleet_test.dart';

void registerAnyExplorerG2Group() {
  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — panel sweep true branches',
    () {
      testWidgets('single Assign row with enabled Explore tile -> true', (
        tester,
      ) async {
        var assignTaps = 0;
        await tester.pumpWidget(
          _wrap(
            _civilianPanel(
              children: [
                _AssignRow(
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
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    label: kUnitTypeBuilder,
                    exploreTileEnabled: false,
                    onTap: () => firstTaps++,
                  ),
                  _AssignRow(
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
