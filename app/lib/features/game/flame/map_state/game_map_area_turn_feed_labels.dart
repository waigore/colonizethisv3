part of 'game_map_area.dart';

/// Display-label and map-locate helpers for [GameMapArea] turn-event feed
/// entries (Refs #3878 Phase 3 map_state modularization).
mixin _GameMapAreaTurnFeedLabels
    on ConsumerState<GameMapArea>, _GameMapAreaStateBase {
  String _factionLabel(String id) =>
      widget.game.factionDisplayNameById(id) ?? id;

  String _provinceLabel(String fullProvinceId) =>
      widget.game.worldState.tryGetProvince(fullProvinceId)?.displayName ??
      fullProvinceId;

  String _seaZoneLabel(String seaZoneId) {
    return widget.game.worldState.seaZoneDisplayNameById[seaZoneId] ??
        seaZoneId;
  }

  String _diplomacyOutcomeLine({
    required String actorId,
    required String targetId,
    required String changeType,
  }) {
    final actor = _factionLabel(actorId);
    final target = _factionLabel(targetId);
    final normalized = changeType.toLowerCase();
    return switch (normalized) {
      'declare_war' => '$actor declared war on $target!',
      'peace' => '$actor and $target signed peace!',
      'alliance' => '$actor and $target formed an alliance!',
      'break_alliance' => '$actor and $target broke their alliance!',
      _ => '$actor and $target diplomacy changed! ${changeType.toUpperCase()}!',
    };
  }

  Set<String> _seaZoneRegionCandidates(String seaZoneId) {
    final regionFromPrefix = prefixedIdRegionSegment(seaZoneId);
    if (regionFromPrefix != null && regionFromPrefix.isNotEmpty) {
      return {regionFromPrefix};
    }
    final localSeaZoneId = prefixedIdLocalSegment(seaZoneId);
    final fromPorts = <String>{};
    for (final key in widget.game.worldState.portsByProvinceSeaboard.keys) {
      final firstPipe = key.indexOf('|');
      if (firstPipe <= 0 || firstPipe + 1 >= key.length) {
        continue;
      }
      final lastPipe = key.lastIndexOf('|');
      final keyRegion = key.substring(0, firstPipe);
      final keySeaZone = key.substring(lastPipe + 1);
      if (keySeaZone == localSeaZoneId && keyRegion.isNotEmpty) {
        fromPorts.add(keyRegion);
      }
    }
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    final fromTopology = <String>{};
    if (mapData == null) {
      return fromPorts;
    }
    for (final entry in mapData.topologyByRegion.entries) {
      if (entry.value.nodes.any(
        (node) =>
            node.type == TopologyNodeType.seaZone && node.id == localSeaZoneId,
      )) {
        fromTopology.add(entry.key);
      }
    }
    return {...fromPorts, ...fromTopology};
  }

  String? _tileKeyForSeaZoneEvent(String seaZoneId) {
    final candidates = _seaZoneRegionCandidates(seaZoneId);
    if (candidates.length != 1) {
      return null;
    }
    final regionId = candidates.first;
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    return tileKeyForNavalFleetAtSea(
      game: widget.game,
      regionId: regionId,
      seaZoneId: seaZoneId,
      tileMap: mapData?.tileMapByRegion[regionId],
      regionTopology: mapData?.topologyByRegion[regionId],
    );
  }

  ct_models.Province? _provinceByPrefixedId(String prefixedProvinceId) =>
      widget.game.worldState.tryGetProvince(prefixedProvinceId);

  void _emitLocateMapTile({
    required String tileKey,
    required String regionId,
  }) {
    ref.read(appEventBusProvider).emit(
          ct_models.LocateMapTileEvent(
            tileKey: tileKey,
            regionId: regionId,
          ),
        );
  }

  void _locateProvinceTile(ct_models.Province province) {
    final tileKey = tileKeyForProvinceLocation(widget.game, province);
    if (tileKey == null) {
      return;
    }
    _emitLocateMapTile(tileKey: tileKey, regionId: province.regionId);
  }

  void _locateProvinceById(String provinceId) {
    final province = _provinceByPrefixedId(provinceId);
    if (province == null) {
      return;
    }
    _locateProvinceTile(province);
  }

  void _locateSeaZoneTile(String seaZoneId) {
    final tileKey = _tileKeyForSeaZoneEvent(seaZoneId);
    if (tileKey == null) {
      return;
    }
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) {
      return;
    }
    _emitLocateMapTile(tileKey: tileKey, regionId: regionId);
  }

  void _locateTileKey(String tileKey) {
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) {
      return;
    }
    _emitLocateMapTile(tileKey: tileKey, regionId: regionId);
  }
}
