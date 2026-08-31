// Slots-tab open-path snapshot and session cache for GAME40001 (Refs #4688 Slice 7).

import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_slot_preview.dart';
import 'research_slot_preview_inputs.dart';

/// Slots-tab open-path projections reused across `GAME40001` reopen.
class TechnologyPanelSlotsOpenPathSnapshot {
  const TechnologyPanelSlotsOpenPathSnapshot({
    required this.researchedIds,
    required this.occupiedPreviewInputs,
    this.slotsTurnPreview,
  });

  final List<String> researchedIds;
  final List<ResearchSlotPreviewInput> occupiedPreviewInputs;
  final ResearchSlotsTurnPreview? slotsTurnPreview;
}

typedef TechnologyPanelSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
  String humanPlayerId,
  int ordersRevision,
  bool canEdit,
});

class TechnologyPanelSessionCacheState {
  const TechnologyPanelSessionCacheState({
    this.revision,
    this.snapshot,
  });

  final TechnologyPanelSessionRevision? revision;
  final TechnologyPanelSlotsOpenPathSnapshot? snapshot;
}

/// Cross-visit cache for `GAME40001` Slots-tab projections.
class TechnologyPanelSessionCache {
  TechnologyPanelSessionCacheState state = const TechnologyPanelSessionCacheState();

  void reset() {
    state = const TechnologyPanelSessionCacheState();
  }
}

List<String> sortedResearchedTechIds(Player player) {
  final techUnlocked = player.techUnlocked ?? const <String, bool>{};
  final researchedIds = techUnlocked.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
  researchedIds.sort(sortTechnologyTechIdsByEraThenName);
  return researchedIds;
}

int sortTechnologyTechIdsByEraThenName(String a, String b) {
  final eraA = techById(a)?.era ?? 999;
  final eraB = techById(b)?.era ?? 999;
  final eraCmp = eraA.compareTo(eraB);
  if (eraCmp != 0) {
    return eraCmp;
  }
  return techDisplayName(a).compareTo(techDisplayName(b));
}

TechnologyPanelSlotsOpenPathSnapshot resolveTechnologyPanelSlotsOpenPath({
  required TechnologyPanelSessionCache cache,
  required TechnologyPanelSessionRevision revision,
  required Game game,
  required Player player,
  required Orders orders,
}) {
  if (cache.state.revision == revision && cache.state.snapshot != null) {
    return cache.state.snapshot!;
  }

  final snapshot = ctAppPerfSync('technology.slotsOpenPath', () {
    final researchedIds = sortedResearchedTechIds(player);
    if (!revision.canEdit) {
      return TechnologyPanelSlotsOpenPathSnapshot(
        researchedIds: researchedIds,
        occupiedPreviewInputs: const [],
      );
    }
    final occupiedPreviewInputs = occupiedResearchSlotPreviewInputs(
      game: game,
      player: player,
      currentOrders: orders,
    );
    final slotsTurnPreview = computeResearchSlotsTurnPreview(
      player: player,
      occupiedSlots: occupiedPreviewInputs,
    );
    return TechnologyPanelSlotsOpenPathSnapshot(
      researchedIds: researchedIds,
      occupiedPreviewInputs: occupiedPreviewInputs,
      slotsTurnPreview: slotsTurnPreview,
    );
  });
  cache.state = TechnologyPanelSessionCacheState(
    revision: revision,
    snapshot: snapshot,
  );
  return snapshot;
}
