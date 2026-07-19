import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/world/minor_military_parity.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// `peasant_levies` (lightInfantry, era 1) and `calivermen` (lightInfantry,
/// era 2) are the regiment-catalog pair used to exercise in-place upgrades.
void main() {
  Game parityGame({
    int gpMilitaryLevel = 2,
    String minorUnitType = 'peasant_levies',
    List<MinorNation> minorNations = const [
      MinorNation(id: 'm1', displayName: 'Minor'),
    ],
    List<Tribe> tribes = const [
      Tribe(id: 't1', displayName: 'Tribe', effectiveMilitaryLevel: 3),
    ],
  }) => TestFixtures.minimalGame(
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP',
        isHuman: true,
        militaryLevel: gpMilitaryLevel,
      ),
    ],
    minorNations: minorNations,
    tribes: tribes,
    oldWorld: RegionData(
      provinces: const [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
      units: [
        Unit(
          id: 'u1',
          type: minorUnitType,
          ownerId: 'm1',
          locationProvinceId: 'oldWorld|p1',
        ),
        Unit(
          id: 'u2',
          type: 'peasant_levies',
          ownerId: 'gp1',
          locationProvinceId: 'oldWorld|p1',
        ),
      ],
    ),
  );

  test('sets minor effective level to max GP level and upgrades regiment', () {
    final result = applyMinorMilitaryParity(parityGame());
    expect(result.minorNations.single.effectiveMilitaryLevel, 2);
    final minorUnit = result.worldState.oldWorld.units.firstWhere(
      (u) => u.id == 'u1',
    );
    expect(minorUnit.type, 'calivermen');
  });

  test('resets every tribe effective level to 1 (no parity)', () {
    final result = applyMinorMilitaryParity(parityGame());
    expect(result.tribes.single.effectiveMilitaryLevel, 1);
  });

  test('leaves non-minor units untouched', () {
    final result = applyMinorMilitaryParity(parityGame());
    final gpUnit = result.worldState.oldWorld.units.firstWhere(
      (u) => u.id == 'u2',
    );
    expect(gpUnit.type, 'peasant_levies');
  });

  test('does not upgrade a regiment already at or above the target era', () {
    final result = applyMinorMilitaryParity(parityGame(gpMilitaryLevel: 1));
    final minorUnit = result.worldState.oldWorld.units.firstWhere(
      (u) => u.id == 'u1',
    );
    expect(minorUnit.type, 'peasant_levies');
  });

  test('keeps regiment unchanged when no catalog entry exists for the era', () {
    final result = applyMinorMilitaryParity(parityGame(gpMilitaryLevel: 99));
    final minorUnit = result.worldState.oldWorld.units.firstWhere(
      (u) => u.id == 'u1',
    );
    expect(minorUnit.type, 'peasant_levies');
  });

  test('returns the same game when there are no minors or tribes', () {
    final game = parityGame(minorNations: const [], tribes: const []);
    expect(identical(applyMinorMilitaryParity(game), game), isTrue);
  });

  test('sets minor level to max across multiple GPs', () {
    final game = TestFixtures.minimalGame(
      players: [
        const Player(id: 'gp1', displayName: 'GP1', isHuman: true, militaryLevel: 2),
        const Player(id: 'gp2', displayName: 'GP2', isHuman: true, militaryLevel: 4),
        const Player(id: 'gp3', displayName: 'GP3', isHuman: true, militaryLevel: 3),
      ],
      minorNations: const [
        MinorNation(id: 'm1', displayName: 'Minor1'),
        MinorNation(id: 'm2', displayName: 'Minor2'),
      ],
      tribes: const [Tribe(id: 't1', displayName: 'Tribe')],
      oldWorld: const RegionData(
        provinces: [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
      ),
    );
    final result = applyMinorMilitaryParity(game);
    expect(result.minorNations[0].effectiveMilitaryLevel, 4);
    expect(result.minorNations[1].effectiveMilitaryLevel, 4);
    expect(result.tribes.single.effectiveMilitaryLevel, 1);
  });

  test('upgrades dual-region regiments in place and preserves medals', () {
    final game = TestFixtures.minimalGame(
      players: [
        const Player(id: 'gp1', displayName: 'GP', isHuman: true, militaryLevel: 4),
      ],
      minorNations: const [MinorNation(id: 'm1', displayName: 'Minor')],
      tribes: const [],
      oldWorld: RegionData(
        provinces: const [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
        units: [
          Unit(
            id: 'u_minor',
            type: 'halberdiers',
            ownerId: 'm1',
            locationProvinceId: 'oldWorld|p1',
            medals: 2,
          ),
          Unit(
            id: 'u_gp',
            type: 'halberdiers',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: const [Province(id: 'newWorld|n1', regionId: 'newWorld')],
        units: [
          Unit(
            id: 'u_minor_nw',
            type: kTechIdHorseArtillery,
            ownerId: 'm1',
            locationProvinceId: 'newWorld|n1',
            medals: 1,
          ),
        ],
      ),
    );
    final result = applyMinorMilitaryParity(game);
    final ow = {for (final u in result.worldState.oldWorld.units) u.id: u};
    final nw = {for (final u in result.worldState.newWorld.units) u.id: u};
    expect(ow['u_minor']!.type, 'rifle_infantry');
    expect(ow['u_minor']!.medals, 2);
    expect(nw['u_minor_nw']!.type, 'field_artillery');
    expect(nw['u_minor_nw']!.medals, 1);
    expect(ow['u_gp']!.type, 'halberdiers');
  });

  test('uses 1 when no GP has militaryLevel set', () {
    final game = TestFixtures.minimalGame(
      players: [const Player(id: 'gp1', displayName: 'GP', isHuman: true)],
      minorNations: const [
        MinorNation(id: 'm1', displayName: 'Minor', effectiveMilitaryLevel: 2),
      ],
      tribes: const [],
      oldWorld: const RegionData(
        provinces: [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
      ),
    );
    final result = applyMinorMilitaryParity(game);
    expect(result.minorNations.single.effectiveMilitaryLevel, 1);
  });
}
