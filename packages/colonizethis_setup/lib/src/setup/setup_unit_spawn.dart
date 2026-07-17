// Shared capital unit spawn + home-fleet merge for base setup and advanced start.
// SPEC/program/game-setup-pipeline.md §7e; SPEC/game/advanced-starts.md steps 5–7.
// Refs #4054.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Builds a civilian unit id for capital spawn (1-based [indexOneBased]).
typedef CivilianUnitIdFormatter =
    String Function({
      required String ownerId,
      required String unitType,
      required int indexOneBased,
    });

/// Builds a regiment unit id for capital spawn (1-based [indexOneBased]).
typedef RegimentUnitIdFormatter =
    String Function({
      required String ownerId,
      required String typeId,
      required int indexOneBased,
    });

/// Default base-setup civilian id: `{owner}_{typeLower}_k`.
String baseSetupCivilianUnitId({
  required String ownerId,
  required String unitType,
  required int indexOneBased,
}) => '${ownerId}_${unitType.toLowerCase()}_$indexOneBased';

/// Advanced-start civilian id: `{owner}_adv_{typeLowerSpacesToUnderscore}_k`.
String advancedStartCivilianUnitId({
  required String ownerId,
  required String unitType,
  required int indexOneBased,
}) {
  final suffix = unitType.toLowerCase().replaceAll(' ', '_');
  return '${ownerId}_adv_${suffix}_$indexOneBased';
}

/// Default base-setup regiment id: `{owner}_{type}_regN`.
String baseSetupRegimentUnitId({
  required String ownerId,
  required String typeId,
  required int indexOneBased,
}) => '${ownerId}_${typeId}_reg$indexOneBased';

/// Advanced-start regiment id: `{owner}_adv_{type}_regN`.
String advancedStartRegimentUnitId({
  required String ownerId,
  required String typeId,
  required int indexOneBased,
}) => '${ownerId}_adv_${typeId}_reg$indexOneBased';

/// Spawns [count] civilian units of [unitType] at the capital tile/region.
void spawnCivilianUnitsOfType({
  required Map<String, List<Unit>> unitsByRegion,
  required String ownerId,
  required String capitalProvinceId,
  required String capitalTileKey,
  required String capitalRegionId,
  required String unitType,
  required int count,
  required CivilianUnitIdFormatter unitIdFor,
  bool includeExpectedRegionsInError = false,
}) {
  final destination = unitsByRegion[capitalRegionId];
  if (destination == null) {
    throw StateError(
      includeExpectedRegionsInError
          ? 'Unknown capital region "$capitalRegionId" for owner=$ownerId; '
              'expected one of $kRegionOldWorld / $kRegionNewWorld.'
          : 'Unknown capital region "$capitalRegionId" for owner=$ownerId',
    );
  }
  for (var k = 1; k <= count; k++) {
    destination.add(
      Unit(
        id: unitIdFor(
          ownerId: ownerId,
          unitType: unitType,
          indexOneBased: k,
        ),
        type: unitType,
        ownerId: ownerId,
        locationProvinceId: capitalProvinceId,
        status: UnitStatus.idle,
        tileKey: capitalTileKey,
      ),
    );
  }
}

/// Spawns one regiment per entry in [regimentTypeIds] at the capital province.
void spawnRegimentsAtCapital({
  required String ownerId,
  required String capitalProvinceId,
  required String regionId,
  required List<String> regimentTypeIds,
  required Map<String, List<Unit>> unitsByRegion,
  required RegimentUnitIdFormatter unitIdFor,
  bool includeExpectedRegionsInError = false,
}) {
  if (regimentTypeIds.isEmpty) return;
  final destination = unitsByRegion[regionId];
  if (destination == null) {
    throw StateError(
      includeExpectedRegionsInError
          ? 'Unknown capital region "$regionId" for player=$ownerId; '
              'expected one of $kRegionOldWorld / $kRegionNewWorld.'
          : 'Unknown capital region "$regionId" for player=$ownerId',
    );
  }
  for (var i = 0; i < regimentTypeIds.length; i++) {
    final typeId = regimentTypeIds[i];
    destination.add(
      Unit(
        id: unitIdFor(
          ownerId: ownerId,
          typeId: typeId,
          indexOneBased: i + 1,
        ),
        type: typeId,
        ownerId: ownerId,
        locationProvinceId: capitalProvinceId,
        status: UnitStatus.idle,
      ),
    );
  }
}

/// Mutable scratch for home-fleet merge loops (fleets copy + seq floor).
({
  List<Fleet> fleets,
  Map<String, int> fleetIndexById,
  int nextSeq,
})
prepareHomeFleetMergeScratch(WorldState worldState) {
  final fleets = List<Fleet>.from(worldState.fleets);
  final fleetIndexById = <String, int>{
    for (var i = 0; i < fleets.length; i++) fleets[i].id: i,
  };
  var nextSeq = worldState.nextShipInstanceSeq;
  final inferredStart = inferNextShipInstanceSeqFromFleets(fleets);
  if (nextSeq < inferredStart) nextSeq = inferredStart;
  return (
    fleets: fleets,
    fleetIndexById: fleetIndexById,
    nextSeq: nextSeq,
  );
}

/// Mints [shipCount] ships of [shipTypeId] into the owner's home fleet.
///
/// When [appendExistingShips] is true, existing home-fleet ships are kept
/// (base setup). When false, the home fleet is replaced with the new instances
/// only (advanced start).
int mergeHomeFleetShips({
  required String ownerId,
  required String regionId,
  required String localProvinceId,
  required int shipCount,
  required String shipTypeId,
  required List<Fleet> fleets,
  required Map<String, int> fleetIndexById,
  required int nextSeq,
  required bool appendExistingShips,
}) {
  if (shipCount <= 0 || regionId != kRegionOldWorld) return nextSeq;
  final fullProvinceId = '$regionId|$localProvinceId';
  final homeFleetId = homeFleetIdFor(ownerId);
  final existingIndex = fleetIndexById[homeFleetId];
  final existingFleet =
      existingIndex != null ? fleets[existingIndex] : null;
  final existingShips = existingFleet?.ships ?? const <ShipInstance>[];
  final (seqAfter, newInstances) = mintShipInstances(
    nextShipInstanceSeq: nextSeq,
    typeIds: [for (var i = 0; i < shipCount; i++) shipTypeId],
  );

  final homeFleet = Fleet(
    id: homeFleetId,
    ownerId: ownerId,
    seaZoneId: null,
    inPortAtProvinceId: fullProvinceId,
    regionId: regionId,
    ships: appendExistingShips
        ? [...existingShips, ...newInstances]
        : newInstances,
  );
  if (existingFleet == null) {
    fleets.add(homeFleet);
    fleetIndexById[homeFleetId] = fleets.length - 1;
  } else {
    fleets[existingIndex!] = homeFleet;
  }
  return seqAfter;
}
