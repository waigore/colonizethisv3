import 'package:flutter/foundation.dart' show immutable;
import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'ct_e2e.dart';

/// Latest province panel inputs while the overlay is open. Only written when [kCtE2EEnabled].
/// **SPEC:** `SPEC/program/e2e-integration-tests.md`.
@immutable
class CtE2eLastPanelSnapshot {
  const CtE2eLastPanelSnapshot({
    required this.game,
    required this.region,
    required this.displayId,
    required this.selectedTileKey,
    required this.humanPlayerId,
    required this.playerView,
    required this.draftOrders,
  });

  final Game game;
  final RegionMapViewData region;
  final String displayId;
  final String selectedTileKey;
  final String humanPlayerId;
  final PlayerView playerView;
  final Orders draftOrders;
}

/// Mutable holder (integration tests read after driving the UI).
CtE2eLastPanelSnapshot? ctE2eLastPanelSnapshot;

void updateCtE2eLastPanelSnapshotIfEnabled(CtE2eLastPanelSnapshot? snapshot) {
  if (!kCtE2EEnabled) {
    return;
  }
  ctE2eLastPanelSnapshot = snapshot;
}
