part of 'capital_choice.dart';

final class _CapitalTileCandidateScan {
  int? classAx;
  int? classAy;
  int? classBx;
  int? classBy;
  int? classCx;
  int? classCy;
  int? classCCoastalX;
  int? classCCoastalY;

  void mergeClassC(int x, int y, TileMapResult tileMap, MapTopology topology) {
    if (classCx == null) {
      classCx = x;
      classCy = y;
    }
    if (_isTileAdjacentToSea(x, y, tileMap, topology) &&
        classCCoastalX == null) {
      classCCoastalX = x;
      classCCoastalY = y;
    }
  }

  void accept(
    CapitalTileClass tileClass,
    int x,
    int y,
    TileMapResult tileMap,
    MapTopology topology,
  ) {
    if (tileClass == CapitalTileClass.a) {
      if (classAx == null) {
        classAx = x;
        classAy = y;
      }
      return;
    }
    if (tileClass == CapitalTileClass.b) {
      if (classBx == null) {
        classBx = x;
        classBy = y;
      }
      return;
    }
    mergeClassC(x, y, tileMap, topology);
  }
}

({
  int? classAx,
  int? classAy,
  int? classBx,
  int? classBy,
  int? classCx,
  int? classCy,
  int? classCCoastalX,
  int? classCCoastalY,
})
_scanCapitalTileCandidates({
  required TileMapResult tileMap,
  required MapTopology topology,
  required String localProvinceId,
  required Set<String> provinceIds,
}) {
  final acc = _CapitalTileCandidateScan();
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      if (tileMap.cell(x, y) != localProvinceId) continue;
      final tileClass = classifyCapitalTile(
        x: x,
        y: y,
        tileMap: tileMap,
        topology: topology,
        localProvinceId: localProvinceId,
        provinceIds: provinceIds,
      );
      acc.accept(tileClass, x, y, tileMap, topology);
    }
  }
  return (
    classAx: acc.classAx,
    classAy: acc.classAy,
    classBx: acc.classBx,
    classBy: acc.classBy,
    classCx: acc.classCx,
    classCy: acc.classCy,
    classCCoastalX: acc.classCCoastalX,
    classCCoastalY: acc.classCCoastalY,
  );
}

String _capitalProvinceIdFromSeaBoundOrFallback(
  List<String> ownedProvinceIds,
  MapTopology topology, {
  required bool requireSeaBound,
}) {
  final seaBound =
      ownedProvinceIds
          .where(
            (id) => isProvinceSeaBound(topology, ProvinceId.localIdFrom(id)),
          )
          .toList()
        ..sort();
  if (seaBound.isNotEmpty) return seaBound.first;
  if (requireSeaBound) {
    throw NoSeaBoundCapitalProvinceException(
      details:
          'No sea-bound province among $ownedProvinceIds; setup must assign at least one sea-bound per faction',
    );
  }
  return (List<String>.from(ownedProvinceIds)..sort()).first;
}

(int, int) _capitalTileXYFromScan({
  required bool requireSeaBound,
  required String provinceId,
  required String regionId,
  required int? classAx,
  required int? classAy,
  required int? classBx,
  required int? classBy,
  required int? classCx,
  required int? classCy,
  required int? classCCoastalX,
  required int? classCCoastalY,
}) {
  if (classAx != null && classAy != null) {
    return (classAx, classAy);
  }
  if (requireSeaBound) {
    if (classCCoastalX != null && classCCoastalY != null) {
      return (classCCoastalX, classCCoastalY);
    }
    throw NoCoastalCapitalTileForGpException(
      details:
          'No coastal tile found in sea-bound province $provinceId in region $regionId',
    );
  }
  if (classBx != null && classBy != null) {
    return (classBx, classBy);
  }
  if (classCx != null && classCy != null) {
    return (classCx, classCy);
  }
  throw SetupTopologyDataException(
    code: 'capital_tile_not_found',
    details: 'No tile found in province $provinceId in region $regionId',
  );
}
