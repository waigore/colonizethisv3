// Demo players for ProductionPanel Widgetbook. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';

/// Full stockpile: enough of every commodity for recipes (and worker luxuries).
Stockpile get _fullStockpile => Stockpile(
      quantities: {
        CommodityCatalog.grain.id: 200,
        CommodityCatalog.meat.id: 200,
        CommodityCatalog.timber.id: 100,
        CommodityCatalog.iron.id: 100,
        CommodityCatalog.wool.id: 80,
        CommodityCatalog.cotton.id: 80,
        CommodityCatalog.coal.id: 60,
        CommodityCatalog.sugarCane.id: 80,
        CommodityCatalog.tobacco.id: 60,
        CommodityCatalog.furs.id: 60,
        CommodityCatalog.copper.id: 60,
        CommodityCatalog.tin.id: 60,
        CommodityCatalog.horses.id: 50,
        CommodityCatalog.lumber.id: 50,
        CommodityCatalog.castIron.id: 50,
        CommodityCatalog.fabric.id: 50,
        CommodityCatalog.refinedSugar.id: 50,
        CommodityCatalog.cigars.id: 20,
        CommodityCatalog.furHats.id: 20,
        CommodityCatalog.steel.id: 30,
        CommodityCatalog.paper.id: 30,
        CommodityCatalog.bronze.id: 30,
      },
    );

/// All worker tiers present; effective labour is high.
WorkerPool get _fullWorkerPool => const WorkerPool(
      peasants: 10,
      apprentices: 5,
      journeymen: 2,
      masters: 1,
    );

/// Player with abundant resources and workers for "full availability" story.
Player fullAvailabilityProductionPlayer() {
  final game = demoGameForOverlay;
  final base = game.players.isNotEmpty ? game.players.first : null;
  if (base == null) {
    return Player(
      id: 'demo',
      displayName: 'Demo',
      isHuman: true,
      stockpile: _fullStockpile,
      workerPool: _fullWorkerPool,
    );
  }
  return base.copyWith(
    stockpile: _fullStockpile,
    workerPool: _fullWorkerPool,
    );
}

/// Limited stockpile: only enough for a few runs of some recipes.
/// Grain covers debug-init military/navy upkeep so worker effective labour matches pool size.
Stockpile get _partialStockpile => Stockpile(
      quantities: {
        CommodityCatalog.grain.id: 500,
        CommodityCatalog.timber.id: 6,
        CommodityCatalog.iron.id: 4,
        CommodityCatalog.coal.id: 2,
        CommodityCatalog.wool.id: 2,
        CommodityCatalog.sugarCane.id: 4,
      },
    );

/// Few workers, peasants only — effective labour = 2.
WorkerPool get _partialWorkerPool => const WorkerPool(
      peasants: 2,
      apprentices: 0,
      journeymen: 0,
      masters: 0,
    );

/// Player with limited resources and workers for "partial availability" story.
Player partialAvailabilityProductionPlayer() {
  final game = demoGameForOverlay;
  final base = game.players.isNotEmpty ? game.players.first : null;
  if (base == null) {
    return Player(
      id: 'demo',
      displayName: 'Demo',
      isHuman: true,
      stockpile: _partialStockpile,
      workerPool: _partialWorkerPool,
    );
  }
  return base.copyWith(
    stockpile: _partialStockpile,
    workerPool: _partialWorkerPool,
  );
}

/// Full-availability player with `cotton_weaving` **not** unlocked, so the
/// `fabric_from_cotton` Allocation row renders locked (visible-but-grayed with
/// the `(locked)` marker) while every other recipe remains available.
/// SPEC/ui/production-panel.md § Tech-gated recipe rows.
Player cottonWeavingLockedProductionPlayer() =>
    fullAvailabilityProductionPlayer().copyWith(
      techUnlocked: const <String, bool>{},
    );

/// Full-availability player with `cotton_weaving` unlocked, so the
/// `fabric_from_cotton` Allocation row renders normally (no `(locked)` marker,
/// interactive). SPEC/ui/production-panel.md § Tech-gated recipe rows.
Player cottonWeavingUnlockedProductionPlayer() =>
    fullAvailabilityProductionPlayer().copyWith(
      techUnlocked: const <String, bool>{kTechIdCottonWeaving: true},
    );

/// Stockpile/worker presets for fast widget tests (avoid `demoGameForOverlay` / debug init).
Stockpile get productionPanelTestFullStockpile => _fullStockpile;

WorkerPool get productionPanelTestFullWorkerPool => _fullWorkerPool;

Stockpile get productionPanelTestPartialStockpile => _partialStockpile;

WorkerPool get productionPanelTestPartialWorkerPool => _partialWorkerPool;
