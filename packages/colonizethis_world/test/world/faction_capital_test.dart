import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/world/faction_capital.dart';

void main() {
  group('capitalTileForFaction / capitalProvinceIdForFaction', () {
    test(
      'Given a player capital When lookup Then returns player fields (positive)',
      () {
        const tile = CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 1, y: 2);
        final game = TestFixtures.singlePlayerGame(
          const Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: tile,
          ),
        );

        expect(capitalTileForFaction(game, 'gp1'), tile);
        expect(capitalProvinceIdForFaction(game, 'gp1'), 'oldWorld|p1');
      },
    );

    test(
      'Given matching player with null capital When lookup Then does not fall '
      'through to minor (negative)',
      () {
        final game = TestFixtures.singlePlayerGame(
          const Player(id: 'gp1', displayName: 'GP', isHuman: true),
        ).copyWith(
          minorNations: [
            const MinorNation(
              id: 'gp1',
              displayName: 'Shadow',
              capitalProvinceId: 'oldWorld|m1',
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'm1',
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        expect(capitalTileForFaction(game, 'gp1'), isNull);
        expect(capitalProvinceIdForFaction(game, 'gp1'), isNull);
      },
    );

    test(
      'Given minor capital When no player match Then returns minor fields '
      '(positive)',
      () {
        const tile = CapitalTile(regionId: 'oldWorld', provinceId: 'm1', x: 3, y: 4);
        final game = TestFixtures.singlePlayerGame(
          const Player(id: 'gp1', displayName: 'GP', isHuman: true),
        ).copyWith(
          minorNations: [
            const MinorNation(
              id: 'm1',
              displayName: 'Minor',
              capitalProvinceId: 'oldWorld|m1',
              capitalTile: tile,
            ),
          ],
        );

        expect(capitalTileForFaction(game, 'm1'), tile);
        expect(capitalProvinceIdForFaction(game, 'm1'), 'oldWorld|m1');
      },
    );

    test(
      'Given tribe capital When no player or minor match Then returns tribe '
      'fields (positive)',
      () {
        const tile = CapitalTile(regionId: 'newWorld', provinceId: 't1', x: 5, y: 6);
        final game = TestFixtures.singlePlayerGame(
          const Player(id: 'gp1', displayName: 'GP', isHuman: true),
        ).copyWith(
          tribes: [
            const Tribe(
              id: 't1',
              displayName: 'Tribe',
              capitalProvinceId: 'newWorld|t1',
              capitalTile: tile,
            ),
          ],
        );

        expect(capitalTileForFaction(game, 't1'), tile);
        expect(capitalProvinceIdForFaction(game, 't1'), 'newWorld|t1');
      },
    );

    test(
      'Given unknown faction id When lookup Then returns null (negative)',
      () {
        final game = TestFixtures.singlePlayerGame(
          const Player(id: 'gp1', displayName: 'GP', isHuman: true),
        );

        expect(capitalTileForFaction(game, 'missing'), isNull);
        expect(capitalProvinceIdForFaction(game, 'missing'), isNull);
      },
    );
  });
}
