part of '../e2e_any_explorer_has_enabled_explore_assign_fleet_test.dart';

void registerAnyExplorerG1Group() {
  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — snapshot short-circuit',
    () {
      testWidgets('snapshot says Explore enabled -> true (no panel sweep)', (
        tester,
      ) async {
        var assignTaps = 0;
        ctE2eCivilianPanelSnapshot = _snapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
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
          ctE2eCivilianPanelSnapshot = _snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad],
            },
          );
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
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
