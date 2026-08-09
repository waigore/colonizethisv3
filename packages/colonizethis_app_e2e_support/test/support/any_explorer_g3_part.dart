part of '../e2e_any_explorer_has_enabled_explore_assign_fleet_test.dart';

void registerAnyExplorerG3Group() {
  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — panel sweep false branches',
    () {
      testWidgets('no Assign rows at all -> false (sweep exhausted)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            _civilianPanel(
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
          _wrap(
            _civilianPanel(
              children: [
                _AssignRow(
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
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
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
