part of 'military_tree_builder.dart';

List<RegimentTypeRow> rowsForArmyUnits(
  Game game,
  Province province,
  List<Unit> units,
  String regionKey,
) {
  final tileKey = tileKeyForProvinceLocation(game, province);
  final byType = <String, List<Unit>>{};
  for (final u in units) {
    byType.putIfAbsent(u.type, () => []).add(u);
  }
  final typeIds = byType.keys.toList()..sort();
  final rows = <RegimentTypeRow>[];
  for (final typeId in typeIds) {
    final list = byType[typeId]!;
    final medals = list.map((u) => u.medals).toSet();
    final medalsSummary = medals.length == 1
        ? '${medals.single}'
        : '${medals.reduce((a, b) => a < b ? a : b)}–${medals.reduce((a, b) => a > b ? a : b)}';
    final status = list.any((u) => u.status == UnitStatus.working)
        ? UnitStatus.working
        : UnitStatus.idle;
    final statusLabel = switch (status) {
      UnitStatus.idle => 'Idle',
      UnitStatus.working => 'Working',
    };
    rows.add(
      RegimentTypeRow(
        typeId: typeId,
        count: list.length,
        medalsSummary: medalsSummary,
        statusLabel: statusLabel,
        tileKey: tileKey,
        regionId: regionKey,
      ),
    );
  }
  return rows;
}

List<Army> _armiesForMilitaryPanel(Game game, String humanPlayerId) {
  return game.worldState.armies
      .where((a) => a.ownerId == humanPlayerId)
      .where((a) => a.isHomeArmy || a.regimentUnitIds.isNotEmpty)
      .toList()
    ..sort((a, b) {
      if (a.isHomeArmy != b.isHomeArmy) {
        return a.isHomeArmy ? -1 : 1;
      }
      return a.id.compareTo(b.id);
    });
}

List<ProvinceArmiesNode> _provinceArmyNodesForRegion({
  required Game game,
  required String regionKey,
  required RegionData regionData,
  required List<Army> armies,
  required Map<String, Unit> unitsById,
}) {
  final provinceById = {
    for (final p in regionData.provinces) '${p.regionId}|${p.id}': p,
    for (final p in regionData.provinces) p.id: p,
  };

  final armiesHere = armies.where((a) {
    final full = ProvinceId.isPrefixed(a.stationedProvinceId)
        ? a.stationedProvinceId
        : ProvinceId.full(regionKey, a.stationedProvinceId);
    final p = game.worldState.tryGetProvince(full);
    return p != null && p.regionId == regionKey;
  }).toList();

  final byProvince = <String, List<Army>>{};
  for (final a in armiesHere) {
    final pid = a.stationedProvinceId;
    final full = ProvinceId.isPrefixed(pid)
        ? pid
        : ProvinceId.full(regionKey, pid);
    byProvince.putIfAbsent(full, () => []).add(a);
  }

  final provinceNodes = <ProvinceArmiesNode>[];
  final provinceIds = byProvince.keys.toList()..sort();
  for (final fullProvinceId in provinceIds) {
    final province = provinceById[fullProvinceId];
    if (province == null) continue;
    final list = byProvince[fullProvinceId]!;
    final blocks = <ArmyBlock>[];
    for (final army in list) {
      final regUnits = <Unit>[
        for (final id in army.regimentUnitIds)
          if (unitsById[id] != null) unitsById[id]!,
      ];
      blocks.add(
        ArmyBlock(
          army: army,
          rows: rowsForArmyUnits(game, province, regUnits, regionKey),
          regionKey: regionKey,
        ),
      );
    }
    provinceNodes.add(ProvinceArmiesNode(province: province, armies: blocks));
  }
  return provinceNodes;
}

List<MilitarySeaZoneNode> _militarySeaZoneNodesForRegion({
  required Game game,
  required String regionKey,
  required String humanPlayerId,
}) {
  final fleetsInRegion = game.worldState.fleets
      .where(
        (f) =>
            f.ownerId == humanPlayerId &&
            f.regionId == regionKey &&
            f.shipTypeIds.isNotEmpty &&
            f.isAtSea &&
            f.seaZoneId != null,
      )
      .toList();
  final bySeaZone = <String, List<Fleet>>{};
  for (final f in fleetsInRegion) {
    final seaZoneId = f.seaZoneId!;
    final zoneKey = prefixedIdHasDelimiter(seaZoneId)
        ? seaZoneId
        : '$regionKey|$seaZoneId';
    bySeaZone.putIfAbsent(zoneKey, () => []).add(f);
  }

  final seaLocations = <MilitarySeaZoneNode>[];
  final seaZoneKeys = bySeaZone.keys.toList()..sort();
  for (final zoneKey in seaZoneKeys) {
    final fleets = bySeaZone[zoneKey]!;
    final shipTypeIds = <String, int>{};
    FleetMission? mission;
    for (final f in fleets) {
      for (final typeId in f.shipTypeIds) {
        shipTypeIds[typeId] = (shipTypeIds[typeId] ?? 0) + 1;
      }
      mission ??= f.mission;
    }
    final zoneLabel = seaZoneDisplayName(
      game: game,
      regionId: regionKey,
      seaZoneId: zoneKey,
    );
    final tileKey = tileKeyForSeaZoneLocation(game, regionKey, zoneKey);
    final rows = <MilitarySeaShipRow>[];
    for (final typeId in shipTypeIds.keys.toList()..sort()) {
      rows.add(
        MilitarySeaShipRow(
          typeId: typeId,
          count: shipTypeIds[typeId]!,
          statusLabel: fleetMissionDisplayLabel(mission ?? FleetMission.none),
          tileKey: tileKey,
          regionId: regionKey,
        ),
      );
    }
    seaLocations.add(
      MilitarySeaZoneNode(
        seaZoneLabel: zoneLabel,
        regionId: regionKey,
        rows: rows,
      ),
    );
  }
  return seaLocations;
}

List<RegionMilitaryGroup> buildMilitaryGroups(Game game, String humanPlayerId) {
  final unitsById = game.worldState.allUnitsById;

  final armies = _armiesForMilitaryPanel(game, humanPlayerId);

  final result = <RegionMilitaryGroup>[];

  game.worldState.forEachRegion((regionKey, regionData) {
    final provinceNodes = _provinceArmyNodesForRegion(
      game: game,
      regionKey: regionKey,
      regionData: regionData,
      armies: armies,
      unitsById: unitsById,
    );

    final seaLocations = _militarySeaZoneNodesForRegion(
      game: game,
      regionKey: regionKey,
      humanPlayerId: humanPlayerId,
    );

    if (provinceNodes.isNotEmpty || seaLocations.isNotEmpty) {
      result.add(
        RegionMilitaryGroup(
          regionKey: regionKey,
          provinces: provinceNodes,
          seaLocations: seaLocations,
        ),
      );
    }
  });

  return result;
}

List<ArmyBlock> flattenMilitaryArmyBlocks(List<RegionMilitaryGroup> groups) {
  final out = <ArmyBlock>[];
  for (final g in groups) {
    for (final p in g.provinces) {
      out.addAll(p.armies);
    }
  }
  return out;
}

bool canCombineArmySelection(
  List<ArmyBlock> flat,
  Set<String> selectedArmyIds,
) {
  if (selectedArmyIds.length < 2) return false;
  final selected = flat
      .where((b) => selectedArmyIds.contains(b.army.id))
      .toList();
  if (selected.length < 2) return false;
  final province = selected.first.army.stationedProvinceId;
  return selected.every((b) => b.army.stationedProvinceId == province);
}
