import 'package:colonizethis_map/src/view/init_game_map_view_data.dart';
import 'package:colonizethis_map/src/view/init_game_map_view_human_player_ids.dart';
import 'package:colonizethis_map/src/view/init_game_map_view_tile_marker_sort.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('tile-marker SoT (#4654)', () {
    test('sorts by y then x then tileKey', () {
      final markers = <CivilianTileMarkerView>[
        _civilian(tileKey: 'r|p|2|1', x: 2, y: 1),
        _civilian(tileKey: 'r|p|1|0', x: 1, y: 0),
        _civilian(tileKey: 'r|p|0|1', x: 0, y: 1),
      ];
      sortTileAnchoredMarkers(
        markers,
        yOf: (m) => m.y,
        xOf: (m) => m.x,
        tileKeyOf: (m) => m.tileKey,
      );
      expect(markers.map((m) => m.tileKey).toList(), [
        'r|p|1|0',
        'r|p|0|1',
        'r|p|2|1',
      ]);
    });

    test('humanPlayerIds keeps only isHuman players', () {
      final game = TestFixtures.minimalGame();
      expect(humanPlayerIds(game), isNotEmpty);
      expect(
        humanPlayerIds(game),
        everyElement(
          isIn(game.players.where((p) => p.isHuman).map((p) => p.id)),
        ),
      );
    });

    test('ProvinceUnitPresenceView.copyWith updates one field', () {
      const base = ProvinceUnitPresenceView(
        civilianCount: 1,
        regimentCount: 2,
        shipCount: 3,
        intelVisible: false,
      );
      final next = base.copyWith(shipCount: 9, intelVisible: true);
      expect(next.civilianCount, 1);
      expect(next.regimentCount, 2);
      expect(next.shipCount, 9);
      expect(next.intelVisible, isTrue);
    });
  });
}

CivilianTileMarkerView _civilian({
  required String tileKey,
  required int x,
  required int y,
}) {
  return CivilianTileMarkerView(
    tileKey: tileKey,
    x: x,
    y: y,
    localProvinceId: 'p',
    unitIds: const ['u'],
    unitTypes: const {'u': 'merchant'},
    representativeUnitType: 'merchant',
    stackCount: 1,
  );
}
