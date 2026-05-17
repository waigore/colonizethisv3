import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('foreignCivilianVisibleToPlayer', () {
    const topology = MapTopology();
    const human = 'gp1';
    const other = 'gp2';

    PlayerView viewWithTile(String tileKey, VisibilityLevel level) {
      return buildPlayerView(
        Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            playerVisibilityByTile: {
              human: {tileKey: level.name},
            },
          ),
          players: const [
            Player(id: human, displayName: 'H', isHuman: true),
            Player(id: other, displayName: 'O', isHuman: false),
          ],
        ),
        topology,
        human,
      );
    }

    test('owner always visible without tile', () {
      final u = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: 'oldWorld|p1',
      );
      final v = viewWithTile('oldWorld|p1|0|0', VisibilityLevel.unknown);
      expect(
        foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: human,
          view: v,
        ),
        isTrue,
      );
    });

    test('foreign visible when tile not unknown', () {
      final u = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: other,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final v = viewWithTile('oldWorld|p1|0|0', VisibilityLevel.fogged);
      expect(
        foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: human,
          view: v,
        ),
        isTrue,
      );
    });

    test('foreign hidden when tile unknown', () {
      final u = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: other,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final v = viewWithTile('oldWorld|p1|0|0', VisibilityLevel.unknown);
      expect(
        foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: human,
          view: v,
        ),
        isFalse,
      );
    });

    test('enemy Spy never visible', () {
      final u = Unit(
        id: 's1',
        type: kUnitTypeSpy,
        ownerId: other,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final v = viewWithTile('oldWorld|p1|0|0', VisibilityLevel.fullyVisible);
      expect(
        foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: human,
          view: v,
        ),
        isFalse,
      );
    });
  });
}
