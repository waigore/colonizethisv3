// Shared Game fixtures for planning OW / tech helper pins (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

const String planningOwTechHelpersGp1 = 'gp1';
const String planningOwTechHelpersGp2 = 'gp2';
const String planningOwTechHelpersGp3 = 'gp3';
const String planningOwTechHelpersTribe1 = 'tribe1';
const String planningOwTechHelpersMinor1 = 'minor1';
const String planningOwTechHelpersGpExhausted = 'gpExhausted';

/// Game where [ownerCounts] maps a factionId to the number of Old World
/// provinces it owns, so `provinceCountOwnedBy` (and hence the
/// `oldWorldProvinceLeadOver` projection under test) returns those counts
/// deterministically via the memoised province-owner cache.
Game planningOwTechHelpersGameOwning(Map<String, int> ownerCounts) {
  final provinces = <Province>[
    for (final entry in ownerCounts.entries)
      for (var i = 0; i < entry.value; i++)
        Province(
          id: 'oldWorld|${entry.key}_$i',
          regionId: 'oldWorld',
          ownerId: entry.key,
        ),
  ];
  return Game(
    id: 'g-3717-ow-lead',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(provinces: []),
    ),
    players: [
      for (final id in ownerCounts.keys)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
  );
}

/// Game whose Great Powers each have [techCountByPlayer] unlocked techs (the
/// `techUnlocked` map carries that many `true` flags), so `unlockedTechCount`
/// and the `isPursuingTechStealPosture` deficit comparison under test resolve
/// deterministically. Minor nations and tribes carry no tech state.
Game planningOwTechHelpersGameWithTechs(Map<String, int> techCountByPlayer) {
  Map<String, bool> techs(int count) => {
    for (var i = 0; i < count; i++) 'tech_$i': true,
  };
  return Game(
    id: 'g-3793-tech-steal',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: [
      for (final entry in techCountByPlayer.entries)
        Player(
          id: entry.key,
          displayName: entry.key.toUpperCase(),
          isHuman: false,
          techUnlocked: techs(entry.value),
        ),
    ],
    minorNations: const [
      MinorNation(
        id: planningOwTechHelpersMinor1,
        displayName: 'Minor1',
      ),
    ],
    tribes: const [
      Tribe(id: planningOwTechHelpersTribe1, displayName: 'Tribe1'),
    ],
  );
}

/// Single-Great-Power game whose treasury and standing-regiment totals are
/// configurable so the mutual-exhausted side qualification can be probed at its
/// economic / military exhaustion ceilings.
Game planningOwTechHelpersGameWithExhaustedGp({
  int treasury = 0,
  int regiments = 0,
}) {
  return Game(
    id: 'g-3717-mutual-exhausted-side',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
      armies: [
        Army(
          id: 'army-$planningOwTechHelpersGpExhausted',
          ownerId: planningOwTechHelpersGpExhausted,
          regionId: 'ow',
          stationedProvinceId: 'ow|home',
          regimentUnitIds: [for (var i = 0; i < regiments; i++) 'reg$i'],
        ),
      ],
    ),
    players: [
      Player(
        id: planningOwTechHelpersGpExhausted,
        displayName: 'Exhausted GP',
        isHuman: false,
        treasury: treasury,
      ),
    ],
  );
}
