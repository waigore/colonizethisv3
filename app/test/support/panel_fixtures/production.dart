// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the structural `ProductionCommodityBreakdownDialog`
/// (PROD20001) suites that only pin **dialog chrome / table layout**
/// (`production_commodity_breakdown_dialog_320dp_min_viewport_test`,
/// `production_commodity_breakdown_dialog_wide_full_width_test`).
///
/// Those suites assert structure only — the localized title, the `Close`
/// `CtNinePatchButton`, the 7-column `DataTable` (commodity + per-phase +
/// total), the wide-path full-width column distribution / no-scrollbar, the
/// narrow-path horizontal `Scrollbar`, and at least one catalog-derived section
/// header (`FOOD` / `RAW MATERIALS` / `MANUFACTURED`). None of that depends on
/// generated map/topology data: the section rows come from the static
/// `CommodityCatalog`, and the per-phase deltas are driven by the
/// `productionDesiredOutputProvider` recipe assignments, not owned tiles. Tests
/// pass `topology: const MapTopology()` and `tileMapByRegion: null`; the
/// economy-preview pipeline returns empty (zero) deltas for a tile-less game, so
/// every commodity renders its `0` cells and the layout assertions hold without
/// the ~7-11 s `getDebugInitGameResult()` map generation.
///
/// The committed wide golden stays on the `getDebugInitGameResult()` allowlist —
/// its pixel baseline was captured against the generated debug-init content, so
/// it cannot move to a hand-built game without re-baselining. The delta-colour
/// pins (positive/negative/zero cell colours) move to
/// [buildProductionBreakdownDeltaTestGame] instead (Refs #3656).
Game buildProductionBreakdownPanelTestGame() =>
    buildPanelTestGame(id: 'production-breakdown-widget-test');

/// Lightweight game shaped for the `production_commodity_breakdown_dialog_spec`
/// **delta-colour** pins (PROD20001): the zero-delta `muted` cells, the
/// positive-delta `success` cells, and the negative-delta `danger` cells.
///
/// The economy-preview pipeline that feeds the dialog
/// (`previewStockpilePhaseDeltasByCommodityForPlayer`) runs its Consumption and
/// Production phases off the player's `workerPool` labour and `stockpile`
/// commodities — **not** owned tiles — so non-zero deltas are reproducible
/// without the ~7-11 s `getDebugInitGameResult()` map generation:
/// - `peasants` are fed `grain` in Consumption (a guaranteed negative `grain`
///   delta) and become idle labour;
/// - that idle labour runs the `lumber_from_timber` recipe when the dialog's
///   `productionDesiredOutputProvider` override assigns it, producing a positive
///   `lumber` delta and consuming `timber` (a negative `timber` delta);
/// - every other commodity stays at `0`, giving the muted zero cells.
///
/// Tests pass `topology: const MapTopology()` and `tileMapByRegion: null`; the
/// Extraction and Riches-to-treasury phases contribute nothing for a tile-less,
/// riches-less game, so only the recipe/consumption deltas above appear.
Game buildProductionBreakdownDeltaTestGame() => buildPanelTestGame(
  id: 'production-breakdown-delta-widget-test',
  players: const [
    Player(
      id: kPanelTestHumanPlayerId,
      displayName: 'Test Human',
      isHuman: true,
      workerPool: WorkerPool(peasants: 20),
      stockpile: Stockpile(
        quantities: {
          'grain': 100,
          'timber': 100,
        },
      ),
    ),
    Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
  ],
);
