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
