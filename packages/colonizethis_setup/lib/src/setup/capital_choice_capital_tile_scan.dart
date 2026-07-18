part of 'capital_choice.dart';

final class _CapitalTileCandidateScan {
  int? classAx;
  int? classAy;
  int? classAPlainsX;
  int? classAPlainsY;
  int? classBx;
  int? classBy;
  int? classBPlainsX;
  int? classBPlainsY;
  int? classCx;
  int? classCy;
  int? classCPlainsX;
  int? classCPlainsY;
  int? classCCoastalX;
  int? classCCoastalY;
  int? classCCoastalPlainsX;
  int? classCCoastalPlainsY;

  bool _isPlains(TileMapResult tileMap, int x, int y) =>
      tileMap.terrainAt(x, y) == TerrainType.plains;

  void mergeClassC(
    int x,
    int y,
    TileMapResult tileMap,
    MapTopology topology,
    Set<String> provinceIds,
  ) {
    if (classCx == null) {
      classCx = x;
      classCy = y;
    }
    if (_isPlains(tileMap, x, y) && classCPlainsX == null) {
      classCPlainsX = x;
      classCPlainsY = y;
    }
    if (_isTileAdjacentToSea(
          x,
          y,
          tileMap,
          topology,
          provinceIds: provinceIds,
        )) {
      if (classCCoastalX == null) {
        classCCoastalX = x;
        classCCoastalY = y;
      }
      if (_isPlains(tileMap, x, y) && classCCoastalPlainsX == null) {
        classCCoastalPlainsX = x;
        classCCoastalPlainsY = y;
      }
    }
  }

  void accept(
    CapitalTileClass tileClass,
    int x,
    int y,
    TileMapResult tileMap,
    MapTopology topology,
    Set<String> provinceIds,
  ) {
    if (tileClass == CapitalTileClass.a) {
      if (classAx == null) {
        classAx = x;
        classAy = y;
      }
      if (_isPlains(tileMap, x, y) && classAPlainsX == null) {
        classAPlainsX = x;
        classAPlainsY = y;
      }
      return;
    }
    if (tileClass == CapitalTileClass.b) {
      if (classBx == null) {
        classBx = x;
        classBy = y;
      }
      if (_isPlains(tileMap, x, y) && classBPlainsX == null) {
        classBPlainsX = x;
        classBPlainsY = y;
      }
      return;
    }
    mergeClassC(x, y, tileMap, topology, provinceIds);
  }
}

({
  int? classAx,
  int? classAy,
  int? classAPlainsX,
  int? classAPlainsY,
  int? classBx,
  int? classBy,
  int? classBPlainsX,
  int? classBPlainsY,
  int? classCx,
  int? classCy,
  int? classCPlainsX,
  int? classCPlainsY,
  int? classCCoastalX,
  int? classCCoastalY,
  int? classCCoastalPlainsX,
  int? classCCoastalPlainsY,
})
_scanCapitalTileCandidates({
  required TileMapResult tileMap,
  required MapTopology topology,
  required String localProvinceId,
  required Set<String> provinceIds,
}) {
  final acc = _CapitalTileCandidateScan();
  forEachProvinceCell(tileMap, localProvinceId, (x, y) {
    final tileClass = classifyCapitalTile(
      x: x,
      y: y,
      tileMap: tileMap,
      topology: topology,
      localProvinceId: localProvinceId,
      provinceIds: provinceIds,
    );
    acc.accept(tileClass, x, y, tileMap, topology, provinceIds);
  });
  return (
    classAx: acc.classAx,
    classAy: acc.classAy,
    classAPlainsX: acc.classAPlainsX,
    classAPlainsY: acc.classAPlainsY,
    classBx: acc.classBx,
    classBy: acc.classBy,
    classBPlainsX: acc.classBPlainsX,
    classBPlainsY: acc.classBPlainsY,
    classCx: acc.classCx,
    classCy: acc.classCy,
    classCPlainsX: acc.classCPlainsX,
    classCPlainsY: acc.classCPlainsY,
    classCCoastalX: acc.classCCoastalX,
    classCCoastalY: acc.classCCoastalY,
    classCCoastalPlainsX: acc.classCCoastalPlainsX,
    classCCoastalPlainsY: acc.classCCoastalPlainsY,
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
  required int? classAPlainsX,
  required int? classAPlainsY,
  required int? classBx,
  required int? classBy,
  required int? classBPlainsX,
  required int? classBPlainsY,
  required int? classCx,
  required int? classCy,
  required int? classCPlainsX,
  required int? classCPlainsY,
  required int? classCCoastalX,
  required int? classCCoastalY,
  required int? classCCoastalPlainsX,
  required int? classCCoastalPlainsY,
}) {
  // Within each class, prefer the first plains tile (row-major); else first tile.
  // Class A still beats Class B regardless of terrain (plains is tertiary).
  if (classAPlainsX != null && classAPlainsY != null) {
    return (classAPlainsX, classAPlainsY);
  }
  if (classAx != null && classAy != null) {
    return (classAx, classAy);
  }
  if (requireSeaBound) {
    if (classCCoastalPlainsX != null && classCCoastalPlainsY != null) {
      return (classCCoastalPlainsX, classCCoastalPlainsY);
    }
    if (classCCoastalX != null && classCCoastalY != null) {
      return (classCCoastalX, classCCoastalY);
    }
    throw NoCoastalCapitalTileForGpException(
      details:
          'No coastal tile found in sea-bound province $provinceId in region $regionId',
    );
  }
  if (classBPlainsX != null && classBPlainsY != null) {
    return (classBPlainsX, classBPlainsY);
  }
  if (classBx != null && classBy != null) {
    return (classBx, classBy);
  }
  if (classCPlainsX != null && classCPlainsY != null) {
    return (classCPlainsX, classCPlainsY);
  }
  if (classCx != null && classCy != null) {
    return (classCx, classCy);
  }
  throw SetupTopologyDataException(
    code: 'capital_tile_not_found',
    details: 'No tile found in province $provinceId in region $regionId',
  );
}
