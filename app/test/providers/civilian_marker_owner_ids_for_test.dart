import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

// Coverage for SPEC/ui/observe-mode.md § Map civilian markers (Refs #2685)
// — the shell-side owner-set helper that the map view provider passes
// straight into `buildInitGameMapViewData` and the draft projection.
void main() {
  suppressLogsForTests();

  group('civilianMarkerOwnerIdsFor', () {
    test(
      'returns null in normal play so the map builder falls back to its '
      'legacy isHuman filter (Refs #2685 AC off)',
      () {
        final game = _twoGpGame();
        final shell = _shell(inObservePhase: false, viewingPlayerId: 'gp1');

        expect(civilianMarkerOwnerIdsFor(shell, game), isNull);
      },
    );

    test(
      'returns the observed GP id only in player observe (Refs #2685 AC '
      'player)',
      () {
        final game = _twoGpGame();
        final shell = _shell(inObservePhase: true, viewingPlayerId: 'gp2');

        expect(civilianMarkerOwnerIdsFor(shell, game), equals({'gp2'}));
      },
    );

    test(
      'returns every player id in global observe (no viewingPlayerId) so '
      'every faction\'s civilians render (Refs #2685 AC global)',
      () {
        final game = _twoGpGame();
        final shell = _shell(inObservePhase: true, viewingPlayerId: null);

        expect(
          civilianMarkerOwnerIdsFor(shell, game),
          equals({'gp1', 'gp2'}),
        );
      },
    );
  });
}

Game _twoGpGame() {
  return Game(
    id: 'civilian_marker_owner_ids',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
        units: [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

ShellPlayerContext _shell({
  required bool inObservePhase,
  required String? viewingPlayerId,
}) {
  return ShellPlayerContext(
    effectiveHumanPlayerId: inObservePhase ? null : viewingPlayerId,
    viewingPlayerId: viewingPlayerId,
    mapVisibilityMode: inObservePhase
        ? CtMapVisibilityMode.full
        : CtMapVisibilityMode.playerConstrained,
    playerView: null,
    omniscientDetail: inObservePhase,
    showPlayerChrome: !inObservePhase || viewingPlayerId != null,
    canMutateViaUi: !inObservePhase,
    debugCommandTargetPlayerId: viewingPlayerId,
    inObservePhase: inObservePhase,
    observeBannerLabel: inObservePhase ? 'Observing: test' : null,
    treasuryNotDefined: inObservePhase && viewingPlayerId == null,
    cargoNotDefined: inObservePhase && viewingPlayerId == null,
  );
}
