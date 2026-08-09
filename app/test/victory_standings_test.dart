import 'package:colonizethis_app/features/game/screens/victory/victory_standings.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'panel_fixtures/core.dart';


Province _owProvince(String localId, String ownerId) {
  return Province(
    id: 'oldWorld|$localId',
    regionId: 'oldWorld',
    ownerId: ownerId,
  );
}

void main() {
  group('buildVictoryStandings', () {
    test('sorts by OW count descending then display name', () {
      final game = buildPanelTestGame(
        players: [
          const Player(id: 'gp1', displayName: 'Zulu', isHuman: true),
          const Player(id: 'gp2', displayName: 'Alpha', isHuman: false),
          const Player(id: 'gp3', displayName: 'Beta', isHuman: false),
        ],
        oldWorldProvinces: [
          _owProvince('p1', 'gp1'),
          _owProvince('p2', 'gp1'),
          _owProvince('p3', 'gp2'),
          _owProvince('p4', 'gp2'),
          _owProvince('p5', 'gp2'),
          _owProvince('p6', 'gp3'),
        ],
      );

      final rows = buildVictoryStandings(game);

      expect(rows.map((r) => r.playerId).toList(), ['gp2', 'gp1', 'gp3']);
      expect(rows[0].owProvinceCount, 3);
      expect(rows[1].owProvinceCount, 2);
      expect(rows[2].owProvinceCount, 1);
    });

    test('power breakdown uses all-world province count for score', () {
      final game = buildPanelTestGame(
        players: [panelTestHumanPlayer()],
        oldWorldProvinces: [_owProvince('p1', 'gp1')],
        newWorldProvinces: [
          const Province(
            id: 'newWorld|nw1',
            regionId: 'newWorld',
            ownerId: 'gp1',
          ),
        ],
      );

      final breakdown = buildVictoryPowerScoreBreakdown(game, 'gp1');

      expect(breakdown.totalProvinces, 2);
      expect(breakdown.provincePoints, 20);
    });
  });
}
