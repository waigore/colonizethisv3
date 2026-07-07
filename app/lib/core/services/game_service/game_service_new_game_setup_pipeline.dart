part of 'game_service.dart';

const int _kLockedFullInitPipelineMaxAttempts = 64;
const int _kFreeformPipelineMaxAttempts = 64;

GameSetupResult _gameServiceFreeformMapsWarpSetupWithRetry({
  required GameSetupConfig cfg,
  required String gameId,
  required int effectiveSeed,
}) {
  final log = packageLogger();
  for (var attempt = 0; attempt < _kFreeformPipelineMaxAttempts; attempt++) {
    final mapSeed = effectiveSeed + attempt * 100003;
    try {
      final ow = _gameServiceGenerateTileMapOldWorld(cfg, mapSeed);
      final nw = _gameServiceGenerateTileMapNewWorld(cfg, mapSeed);
      final warpLinks = _gameServiceGenerateWarpLinks(
        effectiveSeed: mapSeed,
        tileMapOW: ow.$1,
        topoOW: ow.$2,
        tileMapNW: nw.$1,
        topoNW: nw.$2,
      );
      return createGameFromGeneratedMaps(
        config: cfg,
        tileMapOldWorld: ow.$1,
        topologyOldWorld: ow.$2,
        tileMapNewWorld: nw.$1,
        topologyNewWorld: nw.$2,
        gameId: gameId,
        namingSeed: effectiveSeed,
        warpLinks: warpLinks,
      );
    } on SetupTopologyDataException catch (e, st) {
      final retriableTopology =
          e.code == 'assigner_exhausted' ||
          e.code == 'faction_component_bin_pack_failed' ||
          e.code == 'assignment_remainder_not_connected';
      if (retriableTopology && attempt < _kFreeformPipelineMaxAttempts - 1) {
        log.w(
          'app: freeform init topology retry at attempt=$attempt '
          '(code=${e.code}; mapSeed=$mapSeed): $e',
        );
        continue;
      }
      log.e('app: freeform init setup failed: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
  throw SetupTopologyDataException(
    code: 'assigner_exhausted',
    details:
        'Freeform init pipeline exhausted after '
        '$_kFreeformPipelineMaxAttempts attempts',
  );
}

GameSetupResult _gameServiceLockedFullInitMapsWarpSetupWithRetry({
  required GameSetupConfig cfg,
  required String gameId,
  required int effectiveSeed,
}) {
  final log = packageLogger();
  for (
    var attempt = 0;
    attempt < _kLockedFullInitPipelineMaxAttempts;
    attempt++
  ) {
    final mapSeed = effectiveSeed + attempt * 100003;
    try {
      final r = generateLockedFullInitTileMapPair(
        config: cfg,
        effectiveSeed: mapSeed,
        onLog: _mapGenPassLog.d,
      );
      final warpLinks = _gameServiceGenerateWarpLinks(
        effectiveSeed: mapSeed,
        tileMapOW: r.tileOw,
        topoOW: r.topoOw,
        tileMapNW: r.tileNw,
        topoNW: r.topoNw,
      );
      return createGameFromGeneratedMaps(
        config: cfg,
        tileMapOldWorld: r.tileOw,
        topologyOldWorld: r.topoOw,
        tileMapNewWorld: r.tileNw,
        topologyNewWorld: r.topoNw,
        gameId: gameId,
        namingSeed: effectiveSeed,
        warpLinks: warpLinks,
      );
    } on MapPartitionGatesExhaustedException catch (e) {
      if (attempt < _kLockedFullInitPipelineMaxAttempts - 1) {
        log.w(
          'app: locked full-init partition gates exhausted; retrying '
          '(attempt=$attempt mapSeed=$mapSeed): $e',
        );
        continue;
      }
      throw SetupTopologyDataException(
        code: MapPartitionGatesExhaustedException.codeValue,
        details: e.toString(),
      );
    } on SetupTopologyDataException catch (e, st) {
      final retriableTopology =
          e.code == 'assigner_exhausted' ||
          e.code == 'faction_component_bin_pack_failed' ||
          e.code == 'assignment_remainder_not_connected';
      if (retriableTopology &&
          attempt < _kLockedFullInitPipelineMaxAttempts - 1) {
        log.w(
          'app: locked full-init setup topology retry '
          '(attempt=$attempt mapSeed=$mapSeed code=${e.code}): $e',
        );
        continue;
      }
      log.e(
        'app: locked full-init setup failed: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
  throw SetupTopologyDataException(
    code: 'assigner_exhausted',
    details:
        'Locked full-init pipeline exhausted after '
        '$_kLockedFullInitPipelineMaxAttempts attempts',
  );
}
