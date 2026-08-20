import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_fixtures.dart';

InitGameMapViewData armyMarkerView({
  required List<Army> armies,
  List<Player> extraPlayers = const [],
}) {
  return buildViewDataForScenario(
    oldWorldFocusedScenario(
      game: minimalGame(
        id: 'army-markers',
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
            townTileKey: 'oldWorld|p1|0|0',
          ),
        ],
        armies: armies,
        players: [
          const Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
          ...extraPlayers,
        ],
      ),
      oldWorldGrid: const [
        ['p1'],
      ],
      oldWorldTopology: regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1'],
      ),
    ),
  );
}
