import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show kNewWorldRegionId;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('townIconStyleForProvince', () {
    Game gameWith({
      List<Player> players = const [],
      List<MinorNation> minorNations = const [],
      List<Tribe> tribes = const [],
    }) => Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: players,
      minorNations: minorNations,
      tribes: tribes,
    );

    test('Tribe-owned province uses tribal style', () {
      final game = gameWith(
        tribes: [const Tribe(id: 't1', displayName: 'Tribe')],
      );
      expect(
        townIconStyleForProvince(
          regionId: kNewWorldRegionId,
          ownerId: 't1',
          game: game,
        ),
        kTownIconStyleTribal,
      );
    });

    test('Great Power New World province uses colonial style', () {
      final game = gameWith(
        players: [const Player(id: 'gp1', displayName: 'GP', isHuman: false)],
      );
      expect(
        townIconStyleForProvince(
          regionId: kNewWorldRegionId,
          ownerId: 'gp1',
          game: game,
        ),
        kTownIconStyleColonial,
      );
    });

    test('unowned New World province uses colonial style', () {
      final game = gameWith();
      expect(
        townIconStyleForProvince(
          regionId: kNewWorldRegionId,
          ownerId: null,
          game: game,
        ),
        kTownIconStyleColonial,
      );
    });

    test('Great Power Old World province uses euro style', () {
      final game = gameWith(
        players: [const Player(id: 'gp1', displayName: 'GP', isHuman: false)],
      );
      expect(
        townIconStyleForProvince(
          regionId: 'oldWorld',
          ownerId: 'gp1',
          game: game,
        ),
        kTownIconStyleEuro,
      );
    });

    test('Minor Nation Old World province uses euro style', () {
      final game = gameWith(
        minorNations: [const MinorNation(id: 'm1', displayName: 'Minor')],
      );
      expect(
        townIconStyleForProvince(
          regionId: 'oldWorld',
          ownerId: 'm1',
          game: game,
        ),
        kTownIconStyleEuro,
      );
    });
  });

  group('townIconIdFor', () {
    test('clamps level into 1–4', () {
      expect(
        townIconIdFor(style: kTownIconStyleEuro, level: 0),
        'town_euro_1',
      );
      expect(
        townIconIdFor(style: kTownIconStyleEuro, level: 9),
        'town_euro_4',
      );
    });
  });
}
