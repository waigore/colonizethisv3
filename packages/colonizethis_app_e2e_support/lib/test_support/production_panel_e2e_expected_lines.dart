// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for ProductionPanel (wide layout ≥ kNarrowBreakpoint).
// Mirrors app/lib/features/game/widgets/production/production_panel.dart for e2e.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'production_panel_e2e_expected_lines_allocation.dart';
import 'production_panel_e2e_expected_lines_available.dart';

String _labourTierDisplayName(WorkerTier tier, AppLocalizations l10n) {
  switch (tier) {
    case WorkerTier.peasant:
      return l10n.production_workers_peasants;
    case WorkerTier.apprentice:
      return l10n.production_workers_apprentices;
    case WorkerTier.journeyman:
      return l10n.production_workers_journeymen;
    case WorkerTier.master:
      return l10n.production_workers_masters;
  }
}

/// Expected in-order [Text.data] for the Labour Controls section the
/// production panel appends to the Workers section (`ProductionPanel`
/// `_buildWorkerSection`, gated on a non-null `currentOrders`). Mirrors the
/// `CtSectionLabel` header plus one [ProductionLabourSection] row per tier.
///
/// Per-row order matches `ProductionLabourTierRow.build`: the tier name,
/// upkeep gist, optional `Requires:` gist, optional `Queued: N`, then —
/// when [canEdit] is true — the `Disband` label. Cost gist uses `Text.rich`
/// (`data == null`) so the pre-order [Text] collector skips it.
List<String> productionLabourControlsExpectedTexts({
  required Player player,
  required Orders currentOrders,
  required bool canEdit,
  required AppLocalizations l10n,
}) {
  final out = <String>[];
  out.add(l10n.production_labourControlsSectionLabel.toUpperCase());
  final rows = buildProductionLabourRowData(
    player: player,
    currentOrders: currentOrders,
    canEdit: canEdit,
  );
  for (final row in rows) {
    final tierName = _labourTierDisplayName(row.tier, l10n);
    out.add(tierName);
    out.add(labourUpkeepGist(tier: row.tier, l10n: l10n));
    final requires = labourRequiresGist(
      tier: row.tier,
      techUnlocked: row.techUnlocked,
      l10n: l10n,
    );
    if (requires != null) {
      out.add(requires);
    }
    if (row.queuedCount > 0) {
      out.add(l10n.production_labourQueued(row.queuedCount));
    }
    if (canEdit) {
      out.add(l10n.production_labourDisband);
    }
  }
  return out;
}

/// In-order [Text.data] for wide [ProductionPanel] preorder traversal.
List<String> productionPanelWideExpectedTexts(
  CtE2eProductionPanelSnapshot snap,
  AppLocalizations l10n,
) {
  final regimentCounts = regimentTypeCountsForPlayer(
    snap.game.worldState,
    snap.player.id,
  );
  final shipCounts = shipTypeCountsForPlayer(
    snap.game.worldState,
    snap.player.id,
  );
  final labourReadiness = labourReadinessForPlayer(
    game: snap.game,
    topology: snap.topology,
    playerId: snap.player.id,
    foodCounts: MilitaryNavyFoodCounts(
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    ),
    inputs: economyPreviewInputs(
      tileMapByRegion: snap.tileMapByRegion,
      currentOrders: snap.currentOrders,
    ),
  );
  final effectiveLabour = labourReadiness.effectiveLabour;

  final out = <String>[];
  addProductionPanelAvailableTexts(out, snap, l10n, effectiveLabour);
  out.addAll(
    productionLabourControlsExpectedTexts(
      player: snap.player,
      currentOrders: snap.currentOrders,
      canEdit: snap.canEditLabour,
      l10n: l10n,
    ),
  );
  addProductionPanelAllocationTexts(out, snap, l10n, effectiveLabour);
  return out;
}
