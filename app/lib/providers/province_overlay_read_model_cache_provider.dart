import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/game_service/game_service.dart' show GameMapData;
import '../features/game/flame/overlays/province_detail_overlay_host_support_bonus.dart';
import '../features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart';
import 'panel_session_revision.dart'
    show PanelStaticSessionRevision, panelStaticSessionRevision;

/// Province-wide read-model slice reused across MAP20001 close/reopen (Refs #4690 Slice B).
class ProvinceOverlayProvinceReadModel {
  const ProvinceOverlayProvinceReadModel({
    required this.townProductionBonus,
    required this.extractionSnapshot,
    required this.availableByCommodity,
  });

  final Map<String, int> townProductionBonus;
  final ProvinceExtractionSnapshot? extractionSnapshot;
  final Map<String, ProvinceImprovableCommodityCount> availableByCommodity;
}

typedef ProvinceOverlayStaticSessionRevision = PanelStaticSessionRevision;

class ProvinceOverlaySessionCacheState {
  const ProvinceOverlaySessionCacheState({
    this.staticRevision,
    this.humanConnectivity,
    this.provinceReadModelsByDisplayId = const {},
  });

  final ProvinceOverlayStaticSessionRevision? staticRevision;
  final ConnectivityResult? humanConnectivity;
  final Map<String, ProvinceOverlayProvinceReadModel> provinceReadModelsByDisplayId;
}

/// Session cache for MAP20001 province-wide projections (survives overlay close).
class ProvinceOverlaySessionCache {
  ProvinceOverlaySessionCacheState state = const ProvinceOverlaySessionCacheState();

  void reset() {
    state = const ProvinceOverlaySessionCacheState();
  }

  void _clearStaticIfMismatch(ProvinceOverlayStaticSessionRevision revision) {
    if (state.staticRevision == revision) {
      return;
    }
    state = ProvinceOverlaySessionCacheState(staticRevision: revision);
  }

  void storeHumanConnectivity({
    required ProvinceOverlayStaticSessionRevision revision,
    required ConnectivityResult? connectivity,
  }) {
    _clearStaticIfMismatch(revision);
    state = ProvinceOverlaySessionCacheState(
      staticRevision: revision,
      humanConnectivity: connectivity,
      provinceReadModelsByDisplayId: state.provinceReadModelsByDisplayId,
    );
  }

  void storeProvinceReadModel({
    required ProvinceOverlayStaticSessionRevision revision,
    required String displayId,
    required ProvinceOverlayProvinceReadModel readModel,
  }) {
    _clearStaticIfMismatch(revision);
    state = ProvinceOverlaySessionCacheState(
      staticRevision: revision,
      humanConnectivity: state.humanConnectivity,
      provinceReadModelsByDisplayId: {
        ...state.provinceReadModelsByDisplayId,
        displayId: readModel,
      },
    );
  }
}

final provinceOverlayReadModelCacheProvider = Provider<ProvinceOverlaySessionCache>(
  (ref) => ProvinceOverlaySessionCache(),
);

ProvinceOverlayStaticSessionRevision provinceOverlayStaticSessionRevision({
  required Game game,
}) =>
    panelStaticSessionRevision(game);

ProvinceOverlayProvinceReadModel buildProvinceOverlayProvinceReadModel({
  required Game game,
  required String displayId,
  required GameMapData? mapData,
}) {
  return ProvinceOverlayProvinceReadModel(
    townProductionBonus: provinceTownProductionBonusPreview(
      game: game,
      provinceId: displayId,
      mapData: mapData,
    ),
    extractionSnapshot: provinceExtractionSnapshotPreview(
      game: game,
      provinceId: displayId,
      mapData: mapData,
    ),
    availableByCommodity: provinceAvailableResourceCountsPreview(
      game: game,
      provinceId: displayId,
      mapData: mapData,
    ),
  );
}

ProvinceOverlayProvinceReadModel resolveProvinceOverlayProvinceReadModel({
  required ProvinceOverlaySessionCache cache,
  required Game game,
  required String displayId,
  required GameMapData? mapData,
}) {
  final revision = provinceOverlayStaticSessionRevision(game: game);
  final cached = cache.state.provinceReadModelsByDisplayId[displayId];
  if (cache.state.staticRevision == revision && cached != null) {
    return cached;
  }
  final readModel = ctAppPerfSync(
    'provinceOverlay.provinceReadModel.$displayId',
    () => buildProvinceOverlayProvinceReadModel(
      game: game,
      displayId: displayId,
      mapData: mapData,
    ),
  );
  cache.storeProvinceReadModel(
    revision: revision,
    displayId: displayId,
    readModel: readModel,
  );
  return readModel;
}

ConnectivityResult? resolveProvinceOverlayHumanConnectivity({
  required ProvinceOverlaySessionCache cache,
  required Game game,
  required String humanPlayerId,
  required GameMapData? mapData,
}) {
  final revision = provinceOverlayStaticSessionRevision(game: game);
  if (cache.state.staticRevision == revision &&
      cache.state.humanConnectivity != null) {
    return cache.state.humanConnectivity;
  }
  final connectivity = ctAppPerfSync(
    'provinceOverlay.humanConnectivity',
    () => humanConnectivityPreview(
      game: game,
      humanPlayerId: humanPlayerId,
      mapData: mapData,
    ),
  );
  cache.storeHumanConnectivity(revision: revision, connectivity: connectivity);
  return connectivity;
}
