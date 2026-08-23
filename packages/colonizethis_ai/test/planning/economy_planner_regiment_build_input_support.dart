// Shared scaffolding for economy planner regiment build-input production
// contract suites (Refs #3972 / #2847 H8).
//
// Game builders and phase-plan helpers are shared so the production pin file
// stays under the non-comment line gate without dropping coverage.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'economy_planner_regiment_build_input_games.dart';

const kRegimentBuildInputEmptyTopology = MapTopology(nodes: [], edges: []);

Game regimentRebuildProductionGame({
  required int treasury,
  bool hasRegiment = false,
}) {
  return Game(
    id: 'g-h8-production',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        if (hasRegiment)
          const Army(
            id: 'army-gp1-field',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            stationedProvinceId: 'oldWorld|p0',
            regimentUnitIds: ['reg-1'],
          ),
      ],
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: 'oldWorld|p0',
        treasury: treasury,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.wool.id, 10)
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 10),
        workerPool: const WorkerPool(peasants: 12),
      ),
    ],
  );
}

/// A below-quota zero-NW lock-recovery seller whose improvement-input gate
/// (`regimentBuildInputFeedstockImprovementInputCost`) is active: recovered
/// treasury, zero regiments, 3 Old World provinces, zero New World, missing
/// `fabric`, and an owned **unimproved** `wool` resource tile. Holds
/// `timber` + `iron` so the `castIron_from_iron` recipe is feasible,
/// and zero `castIron`. Refs #2847 § H8-extraction castIron residual.
Game castIronImprovementInputGame({
  required int treasury,
  bool gateActive = true,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-h8-castiron-production',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 3; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      // Unimproved wool resource tile in the seller's capital province (only
      // present when the gate should be active).
      resourceByTileKey: gateActive
          ? const {'oldWorld|seller_0|1|0': 'wool'}
          : const {},
    ),
    players: [
      Player(
        id: 'gp_seller',
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        treasury: treasury,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 10),
        workerPool: const WorkerPool(peasants: 12),
      ),
    ],
  );
}

/// A two-GP game pairing a locked seller (castIron improvement-input gate
/// active, like [castIronImprovementInputGame]) with an affluent supplier
/// (`gp_supplier`) holding `timber` + `iron` feedstock and ample labour, above
/// the conquest quota so it is **not** a lock-recovery seller. Refs #2847
/// H8-supply castIron source. When [sellerGateActive] is false the seller holds
/// `castIron`, so no locked seller needs the improvement input and the supplier
/// over-production trigger is off (negative control).
Game supplierCastIronSourceGame({
  required int treasury,
  bool sellerGateActive = true,
  int sellerOwProvinces = 3,
  int supplierIronHeld = 40,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-h8-castiron-supplier-source',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < sellerOwProvinces; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
          for (var i = 0; i < 12; i++)
            Province(
              id: '$ow|supplier_$i',
              regionId: ow,
              ownerId: 'gp_supplier',
            ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: const {'oldWorld|seller_0|1|0': 'wool'},
    ),
    players: [
      Player(
        id: 'gp_seller',
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        treasury: treasury,
        stockpile: sellerGateActive
            ? const Stockpile().applyDelta(CommodityCatalog.grain.id, 30)
            : const Stockpile()
                  .applyDelta(CommodityCatalog.grain.id, 30)
                  .applyDelta(CommodityCatalog.castIron.id, 1),
        workerPool: const WorkerPool(peasants: 12),
      ),
      Player(
        id: 'gp_supplier',
        displayName: 'Supplier',
        isHuman: false,
        capitalProvinceId: '$ow|supplier_0',
        treasury: treasury,
        // Ample feedstock + labour and no competing output shortage (every
        // feasible output held at the shortage threshold, 8) so the supplier
        // has genuine spare capacity: the small leftover-capacity castIron
        // release boost is the differentiator, not shortage scoring.
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 80)
            .applyDelta(CommodityCatalog.timber.id, 40)
            .applyDelta(CommodityCatalog.iron.id, supplierIronHeld)
            .applyDelta(CommodityCatalog.castIron.id, 8)
            .applyDelta(CommodityCatalog.lumber.id, 8)
            .applyDelta(CommodityCatalog.paper.id, 8),
        workerPool: const WorkerPool(peasants: 40),
      ),
    ],
  );
}

/// A below-quota zero-NW lock-recovery seller whose castIron improvement-input
/// gate is active, with **configurable** `timber` / `iron` feedstock so a test
/// can pin the partial-feedstock state where the single-input
/// `lumber_from_timber` recipe would otherwise drain the `timber` the
/// multi-input `castIron_from_iron` recipe is assembling
/// (Refs #2847 § H8-extraction feedstock co-availability). When [gateActive] is
/// false the unimproved feedstock tile is removed, so the seller is no longer a
/// reserve-target GP (negative control — no feedstock reservation).
