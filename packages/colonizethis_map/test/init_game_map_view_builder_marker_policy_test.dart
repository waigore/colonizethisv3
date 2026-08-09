import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';
import 'support/init_game_map_view_marker_policy_scenarios.dart';

void main() {
  // Regression coverage for SPEC/ui/observe-mode.md § Map civilian markers
  // (Refs #2685): the base map view filter must not depend on Player.isHuman
  // when an explicit civilianMarkerOwnerIds set is provided.
  group('buildInitGameMapViewData civilianMarkerOwnerIds', () {
    InitGameMapViewData renderView({
      required Game game,
      required Set<String>? civilianMarkerOwnerIds,
    }) {
      return buildViewDataForScenario(
        markerPolicyTwoGpScenario(game),
        civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      );
    }

    test(
      'global observe owner set: every GP civilian gets a marker even when '
      'isHuman is false on every player (Refs #2685 AC global)',
      () {
        // Mirrors observe handoff: all players have isHuman=false.
        final game = markerPolicyTwoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: {'gp1', 'gp2'},
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(2));
        expect(
          markers.map((m) => m.tileKey).toList()..sort(),
          equals(['oldWorld|p1|0|0', 'oldWorld|p2|1|0']),
        );
      },
    );

    test(
      'player observe owner set: only the observed GP civilian gets a marker '
      '(Refs #2685 AC player)',
      () {
        final game = markerPolicyTwoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: {'gp2'},
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(1));
        expect(markers.single.tileKey, 'oldWorld|p2|1|0');
        expect(markers.single.unitIds, equals(['gp2_explorer']));
      },
    );

    test(
      'civilianMarkerOwnerIds null falls back to Player.isHuman (legacy '
      'single-player; observe-off no regression — Refs #2685 AC off)',
      () {
        final game = markerPolicyTwoGpGame(gp1Human: true, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: null,
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(1));
        expect(markers.single.tileKey, 'oldWorld|p1|0|0');
        expect(markers.single.unitIds, equals(['gp1_builder']));
      },
    );

    test(
      'civilianMarkerOwnerIds null after observe handoff (no human) yields '
      'no markers — proves the legacy fallback is the documented bug '
      'callers must avoid (Refs #2685 root cause)',
      () {
        final game = markerPolicyTwoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: null,
        );

        expect(view.oldWorld.civilianTileMarkers, isEmpty);
      },
    );

    test(
      'civilianMarkerOwnerIds excludes non-civilian and other-owner units '
      '(negative coverage)',
      () {
        final game = markerPolicyTwoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: {'gp1'},
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(1));
        expect(markers.single.tileKey, 'oldWorld|p1|0|0');
        expect(
          markers.single.unitIds,
          isNot(contains('gp2_explorer')),
          reason: 'gp2 owner is excluded from the owner set',
        );
      },
    );
  });

  group('buildInitGameMapViewData port/town co-location', () {
    test(
      'town markers: co-located port and town shifts port drawable to N sea cell',
      () {
        final game = markerPolicyTownPortColocGame();
        final viewData = buildViewDataForScenario(
          markerPolicyTownPortColocScenario(game),
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.isPort, isTrue);
        expect(tm.x, 1);
        expect(tm.y, 1);
        expect(tm.portIconX, 1);
        expect(tm.portIconY, 0);
      },
    );
    test(
      'town markers: isPort from seaboard key when value province segment mismatches',
      () {
        final game = markerPolicyNonCapitalPortKeyGame();
        final viewData = buildViewDataForScenario(
          markerPolicyNonCapitalPortKeyScenario(game),
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.provinceId, 'p2');
        expect(tm.isPort, isTrue);
        expect(tm.portIconX, 2);
        expect(tm.portIconY, 1);
        expect(viewData.oldWorld.portMarkers.single.provinceId, 'p2');
      },
    );
  });

  group('buildInitGameMapViewData', () {
    test(
      'civilian markers include explicit owner ids when isHuman is false',
      () {
        final game = markerPolicyObserveCivilianGame();
        final scenario = markerPolicyObserveCivilianScenario(game);

        expect(
          buildViewDataForScenario(scenario).oldWorld.civilianTileMarkers,
          isEmpty,
        );
        expect(
          buildViewDataForScenario(
            scenario,
            civilianMarkerOwnerIds: {'gp1', 'gp2'},
          ).oldWorld.civilianTileMarkers,
          hasLength(2),
        );
      },
    );
  });
}
