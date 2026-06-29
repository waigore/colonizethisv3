part of 'game_setup_create.dart';

({
  List<String> gpIds,
  List<String> minorIds,
  List<String> tribeIds,
  List<Province> oldWorldProvinces,
  List<Province> newWorldProvinces,
})
_assignInitialOwnership({
  required GameSetupConfig config,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
}) {
  final owProvinceIds = provinceIdsFromTopology(topologyOldWorld);
  final nwProvinceIds = provinceIdsFromTopology(topologyNewWorld);
  if (owProvinceIds.length < config.greatPowerCount) {
    throw SetupConfigConstraintException(
      code: 'insufficient_old_world_provinces_for_great_powers',
      details:
          'Old World has ${owProvinceIds.length} provinces but ${config.greatPowerCount} Great Powers need at least one each',
    );
  }
  final seaBoundOW =
      owProvinceIds
          .where((id) => isProvinceSeaBound(topologyOldWorld, id))
          .toList()
        ..sort();
  if (seaBoundOW.length < config.greatPowerCount) {
    throw NoSeaBoundCapitalProvinceException(
      details:
          'Old World has ${seaBoundOW.length} sea-bound provinces but ${config.greatPowerCount} Great Powers need one each',
    );
  }
  final gpIds = List.generate(config.greatPowerCount, (i) => 'gp${i + 1}');
  final minorIds = List.generate(
    config.minorNationCount,
    (i) => 'minor${i + 1}',
  );
  final tribeIds = List.generate(config.tribeCount, (i) => 'tribe${i + 1}');
  final owOwner = _assignOldWorldOwners(
    config: config,
    topologyOldWorld: topologyOldWorld,
    provinceIds: owProvinceIds,
    seaBoundOW: seaBoundOW,
    gpIds: gpIds,
    minorIds: minorIds,
  );
  final nwOwner = _assignNewWorldOwners(
    config: config,
    topologyNewWorld: topologyNewWorld,
    provinceIds: nwProvinceIds,
    tribeIds: tribeIds,
  );
  return (
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
    oldWorldProvinces: owOwner.entries
        .map(
          (e) => Province(
            id: ProvinceId.full(kRegionOldWorld, e.key),
            regionId: kRegionOldWorld,
            ownerId: e.value,
          ),
        )
        .toList(),
    newWorldProvinces: nwOwner.entries
        .map(
          (e) => Province(
            id: ProvinceId.full(kRegionNewWorld, e.key),
            regionId: kRegionNewWorld,
            ownerId: e.value,
          ),
        )
        .toList(),
  );
}

Map<String, String> _assignOldWorldOwners({
  required GameSetupConfig config,
  required MapTopology topologyOldWorld,
  required List<String> provinceIds,
  required List<String> seaBoundOW,
  required List<String> gpIds,
  required List<String> minorIds,
}) {
  final owNeighbours = provinceNeighboursFromTopology(topologyOldWorld);
  final useLockedSixMinorContinentPainting =
      config.isLockedFullInitProfile &&
      oldWorldPartitionMatchesLockedProfile(topologyOldWorld) &&
      lockedOldWorldRoleFeasibilityHolds(
        topology: topologyOldWorld,
        neighbours: owNeighbours,
      );
  final owAssignmentRandom = useLockedSixMinorContinentPainting
      ? Random(config.seed)
      : null;
  try {
    return assignOldWorldOwnershipContiguous(
      neighbours: owNeighbours,
      provinceIds: provinceIds,
      seaBoundProvinceIds: seaBoundOW,
      gpIds: gpIds,
      minorIds: minorIds,
      minProvincesPerMinor: config.minProvincesPerMinor,
      assignmentRandom: owAssignmentRandom,
      useLockedSixMinorContinentPainting: useLockedSixMinorContinentPainting,
    );
  } on StateError catch (e, st) {
    if (useLockedSixMinorContinentPainting) {
      gameSetupLog.e(
        'logic: OW locked assignment failed. '
        '${lockedOwAssignFailureDiagnostics(config: config, topology: topologyOldWorld, seaBoundIds: seaBoundOW)} '
        'raw=$e',
        error: e,
        stackTrace: st,
      );
    } else {
      gameSetupLog.e(
        'logic: OW assignment failed: $e',
        error: e,
        stackTrace: st,
      );
    }
    throw SetupTopologyDataException(
      code: 'assigner_exhausted',
      details: 'Old World locked assigner exhausted: $e',
    );
  }
}

Map<String, String> _assignNewWorldOwners({
  required GameSetupConfig config,
  required MapTopology topologyNewWorld,
  required List<String> provinceIds,
  required List<String> tribeIds,
}) {
  final Map<String, String> owners;
  try {
    owners = assignNewWorldOwnershipContiguous(
      topologyNewWorld: topologyNewWorld,
      provinceIds: provinceIds,
      tribeIds: tribeIds,
    );
  } on StateError catch (e, st) {
    if (config.isLockedFullInitProfile) {
      gameSetupLog.e(
        'logic: NW locked assignment failed. '
        '${lockedNwAssignFailureDiagnostics(config: config, topology: topologyNewWorld)} '
        'raw=$e',
        error: e,
        stackTrace: st,
      );
    } else {
      gameSetupLog.e(
        'logic: NW assignment failed: $e',
        error: e,
        stackTrace: st,
      );
    }
    throw SetupTopologyDataException(
      code: 'assigner_exhausted',
      details: 'New World locked assigner exhausted: $e',
    );
  }
  _assertEveryTribeOwnsSeaBoundProvince(
    config: config,
    topologyNewWorld: topologyNewWorld,
    tribeIds: tribeIds,
    owners: owners,
  );
  return owners;
}

/// Enforces the locked full-init guarantee that every Tribe owns at least one
/// sea-bound (P–S) New World province so every Tribe is discoverable by fleet
/// entry (parallel to the GP sea-bound seed rule). On violation throws a
/// retriable [SetupTopologyDataException] (`tribe_missing_sea_bound_province`)
/// so the bounded regen loop regenerates the tile-map pair with a bumped seed.
/// SPEC: game-setup.md § Tribe Assignment, game-setup-pipeline.md step 6.
void _assertEveryTribeOwnsSeaBoundProvince({
  required GameSetupConfig config,
  required MapTopology topologyNewWorld,
  required List<String> tribeIds,
  required Map<String, String> owners,
}) {
  if (!config.isLockedFullInitProfile) return;
  if (tribeIds.isEmpty) return;
  final tribeIdSet = tribeIds.toSet();
  final ownsSeaBound = <String, bool>{for (final t in tribeIds) t: false};
  for (final entry in owners.entries) {
    final ownerId = entry.value;
    if (!tribeIdSet.contains(ownerId)) continue;
    if (ownsSeaBound[ownerId] == true) continue;
    if (isProvinceSeaBound(topologyNewWorld, entry.key)) {
      ownsSeaBound[ownerId] = true;
    }
  }
  final without = ownsSeaBound.entries
      .where((e) => !e.value)
      .map((e) => e.key)
      .toList()
    ..sort();
  if (without.isEmpty) return;
  throw SetupTopologyDataException(
    code: 'tribe_missing_sea_bound_province',
    details:
        'New World tribe assignment left tribe(s) ${without.join(",")} with no '
        'sea-bound (P–S) province under the locked full-init profile; '
        'regenerate the tile-map pair and retry.',
  );
}
