import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  group('applyFactionTerminalFall', () {
    const ow = 'oldWorld';
    const nw = 'newWorld';

    test(
      'minor falls when no owned provinces remain in original capital region; '
      'all provinces and units/fleets transferred or removed',
      () {
        final game = Game(
          id: 'g-minor-fall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: '$ow|P1',
                  regionId: ow,
                  ownerId: 'human_1',
                  townTileKey: '$ow|P1|0|0',
                ),
                Province(
                  id: '$ow|P2',
                  regionId: ow,
                  ownerId: 'human_1',
                  townTileKey: '$ow|P2|1|1',
                ),
              ],
              units: [
                Unit(
                  id: 'unit_1',
                  type: 'peasant_levies',
                  ownerId: 'minor_1',
                  locationProvinceId: '$ow|P2',
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: '$nw|N1',
                  regionId: nw,
                  ownerId: 'minor_1',
                  townTileKey: '$nw|N1|2|2',
                ),
              ],
            ),
            fleets: [
              Fleet(
                id: 'fleet_1',
                ownerId: 'minor_1',
                regionId: nw,
                seaZoneId: '$nw|sea1',
              ),
              Fleet(
                id: 'fleet_2',
                ownerId: 'human_1',
                regionId: nw,
                seaZoneId: '$nw|sea1',
              ),
            ],
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'minor_1', displayName: 'Minor'),
          ],
        );

        final next = applyFactionTerminalFall(
          game,
          previousCapitalByMinor: const {'minor_1': '$ow|P1'},
          previousCapitalByTribe: const {},
        );

        expect(next.minorNations, isEmpty);
        final nwProvince = next.worldState.newWorld.provinces.single;
        expect(nwProvince.id, '$nw|N1');
        expect(nwProvince.ownerId, 'human_1');
        expect(next.worldState.oldWorld.units, isEmpty);
        expect(next.worldState.fleets.length, 1);
        expect(next.worldState.fleets.single.ownerId, 'human_1');
      },
    );

    test(
      'tribe falls when no owned provinces remain in original capital region',
      () {
        final game = Game(
          id: 'g-tribe-fall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
            oldWorld: const RegionData(),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: '$nw|N1',
                  regionId: nw,
                  ownerId: 'human_1',
                  townTileKey: '$nw|N1|0|0',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          tribes: const [Tribe(id: 'tribe_1', displayName: 'Tribe')],
        );

        final next = applyFactionTerminalFall(
          game,
          previousCapitalByMinor: const {},
          previousCapitalByTribe: const {'tribe_1': '$nw|N1'},
        );

        expect(next.tribes, isEmpty);
      },
    );

    test(
      'no fall when minor still owns provinces in original capital region',
      () {
        final game = Game(
          id: 'g-minor-no-fall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: '$ow|P1',
                  regionId: ow,
                  ownerId: 'human_1',
                  townTileKey: '$ow|P1|0|0',
                ),
                Province(
                  id: '$ow|P2',
                  regionId: ow,
                  ownerId: 'minor_1',
                  townTileKey: '$ow|P2|1|1',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'minor_1', displayName: 'Minor'),
          ],
        );

        final next = applyFactionTerminalFall(
          game,
          previousCapitalByMinor: const {'minor_1': '$ow|P1'},
          previousCapitalByTribe: const {},
        );

        expect(next.minorNations, isNotEmpty);
        expect(next.worldState.oldWorld.provinces.length, 2);
      },
    );

    test(
      'no fall when minor still owns the previous capital province '
      '(skipped without trigger)',
      () {
        final game = Game(
          id: 'g-minor-still-capital',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: '$ow|P1',
                  regionId: ow,
                  ownerId: 'minor_1',
                  townTileKey: '$ow|P1|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'minor_1', displayName: 'Minor'),
          ],
        );

        final next = applyFactionTerminalFall(
          game,
          previousCapitalByMinor: const {'minor_1': '$ow|P1'},
          previousCapitalByTribe: const {},
        );

        expect(next.minorNations, isNotEmpty);
      },
    );
  });
}
