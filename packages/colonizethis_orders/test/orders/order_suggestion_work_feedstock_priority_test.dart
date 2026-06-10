import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        feedstockBootstrapBuildImprovementCastIronWaived,
        feedstockExtractionResourceIdsForPlayer;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847 § H8-extraction: feedstock-extraction priority for
// `build_improvement` candidates (SPEC/program/order-suggestions.md).
//
// The worker suggestion pipeline emits only the first lexicographically-sorted
// accepted `build_improvement` candidate per Builder, so without feedstock-
// priority reordering the lone suggested tile is the lex-smallest resource tile
// (here the `grain` tile), and the Full-AI feedstock score boost is inert.
//
// Fixture mirrors `full_ai_civilian_work_supplier_feedstock_extraction_test`:
// an above-quota affluent supplier (`_supplierId`) and a below-quota zero-NW
// lock-recovery seller (`_sellerId`) that needs the `castIron` improvement
// input but holds none, so the supplier-side feedstock-extraction gate for
// `_supplierId` returns `{timber, iron}`.
const _supplierId = 'gp1';
const _sellerId = 'gp2';

// The grain tile key is lexicographically smaller than the timber tile key, so
// ordinary build-improvement suggestion ordering (lexicographic) would emit the
// grain tile. Only the feedstock-priority reordering promotes the unimproved
// `timber` feedstock tile ahead of it.
const _supplierGrainTile = 'oldWorld|gp1-s0|0|0';
const _supplierTimberTile = 'oldWorld|gp1-s0|1|0';
const _sellerWoolTile = 'oldWorld|gp2-p0|0|0';

/// Builds a two-player world that activates the supplier-side feedstock gate
/// for [_supplierId] when [sellerOw] is below the conquest quota (the default).
/// When [sellerOw] is at the quota, no peer needs the improvement input and the
/// supplier gate is empty (negative control).
Game _game({int sellerOw = 5, int supplierCastIron = 0, int sellerNw = 0}) {
  const supplierOw = kObserverConquestMinOwProvincesPerGp;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|gp1-s$i',
        regionId: kRegionOldWorld,
        ownerId: _supplierId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|gp2-p$i',
        regionId: kRegionOldWorld,
        ownerId: _sellerId,
      ),
  ];
  // Optional New World provinces owned by the seller. A below-quota seller that
  // owns any New World province is no longer a zero-NW lock-recovery seller, so
  // its (and the peer supplier's) feedstock gate must deactivate.
  final newWorldProvinces = <Province>[
    for (var i = 0; i < sellerNw; i++)
      Province(
        id: 'newWorld|gp2-n$i',
        regionId: kRegionNewWorld,
        ownerId: _sellerId,
      ),
  ];
  final builder = Unit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: _supplierId,
    locationProvinceId: 'oldWorld|gp1-s0',
    tileKey: _supplierGrainTile,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: provinces, units: [builder]),
    newWorld: RegionData(provinces: newWorldProvinces),
    playerVisibilityByTile: const {
      _supplierId: {
        _supplierGrainTile: 'fullyVisible',
        _supplierTimberTile: 'fullyVisible',
      },
    },
    tileKeysByRegionAndProvince: const {
      kRegionOldWorld: {
        'oldWorld|gp1-s0': [_supplierGrainTile, _supplierTimberTile],
        'oldWorld|gp2-p0': [_sellerWoolTile],
      },
    },
    resourceByTileKey: const {
      _supplierGrainTile: 'grain',
      _supplierTimberTile: 'timber',
      _sellerWoolTile: 'wool',
    },
    tileState: TileMapState(
      improvementByTile: const {
        _supplierGrainTile: 0,
        _supplierTimberTile: 0,
        _sellerWoolTile: 0,
      },
    ),
  );
  return Game(
    id: 'g',
    worldState: world,
    players: [
      Player(
        id: _supplierId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        stockpile: Stockpile(
          quantities: {
            'lumber': 10,
            if (supplierCastIron > 0) 'castIron': supplierCastIron,
          },
        ),
      ),
      Player(
        id: _sellerId,
        displayName: 'Seller',
        isHuman: false,
        // Recovered treasury, zero regiments, no fabric and no castIron, holds
        // only lumber → lock-recovery seller that still needs castIron.
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(quantities: {'lumber': 1}),
      ),
    ],
  );
}

// Co-availability fixture: the supplier owns an unimproved `timber` tile AND
// an unimproved `iron` tile (both feedstock of `castIron`). The timber tile key
// sorts lexicographically before the iron tile key, so ordinary feedstock-
// priority ordering would emit the timber tile. Only the co-availability
// ordering (least-held feedstock first) promotes the `iron` tile when the
// supplier already holds `timber` but no `iron`.
const _coAvailTimberTile = 'oldWorld|gp1-s0|1|0';
const _coAvailIronTile = 'oldWorld|gp1-s0|2|0';

/// Two-player world whose supplier-side feedstock gate is active and that owns
/// an unimproved `timber` tile and an unimproved `iron` tile. The supplier
/// holds [supplierTimberHeld] `timber` and [supplierIronHeld] `iron`.
Game _coAvailGame({int supplierTimberHeld = 13, int supplierIronHeld = 0}) {
  const supplierOw = kObserverConquestMinOwProvincesPerGp;
  const sellerOw = 5;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|gp1-s$i',
        regionId: kRegionOldWorld,
        ownerId: _supplierId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|gp2-p$i',
        regionId: kRegionOldWorld,
        ownerId: _sellerId,
      ),
  ];
  final builder = Unit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: _supplierId,
    locationProvinceId: 'oldWorld|gp1-s0',
    tileKey: _coAvailTimberTile,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: provinces, units: [builder]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      _supplierId: {
        _coAvailTimberTile: 'fullyVisible',
        _coAvailIronTile: 'fullyVisible',
      },
    },
    // The iron tile is a mineral and must be prospected before a Builder may
    // `build_improvement` it (work_order_target_prechecks.dart). Pre-prospect it
    // so this fixture isolates the build_improvement co-availability ordering.
    playerProspectedTiles: const {
      _supplierId: {_coAvailIronTile},
    },
    tileKeysByRegionAndProvince: const {
      kRegionOldWorld: {
        'oldWorld|gp1-s0': [_coAvailTimberTile, _coAvailIronTile],
        'oldWorld|gp2-p0': [_sellerWoolTile],
      },
    },
    resourceByTileKey: const {
      _coAvailTimberTile: 'timber',
      _coAvailIronTile: 'iron',
      _sellerWoolTile: 'wool',
    },
    tileState: TileMapState(
      improvementByTile: const {
        _coAvailTimberTile: 0,
        _coAvailIronTile: 0,
        _sellerWoolTile: 0,
      },
    ),
  );
  return Game(
    id: 'g',
    worldState: world,
    players: [
      Player(
        id: _supplierId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        stockpile: Stockpile(
          quantities: {
            'lumber': 10,
            if (supplierTimberHeld > 0) 'timber': supplierTimberHeld,
            if (supplierIronHeld > 0) 'iron': supplierIronHeld,
          },
        ),
      ),
      Player(
        id: _sellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(quantities: {'lumber': 1}),
      ),
    ],
  );
}

MapTopology _topology(Game game) {
  return MapTopology(
    nodes: [
      for (final p in game.worldState.oldWorld.provinces)
        TopologyNode(
          id: ProvinceId.localIdFrom(p.id),
          regionId: kRegionOldWorld,
          type: TopologyNodeType.province,
        ),
    ],
    edges: const [],
  );
}

List<WorkOrder> _buildImprovementSuggestions(Game game) {
  final topology = _topology(game);
  final view = buildPlayerView(game, topology, _supplierId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  return suggestions
      .where(
        (o) => o.unitId == 'b1' && o.target == kWorkTargetBuildImprovement,
      )
      .toList();
}

void main() {
  group(
    'suggestWorkOrders feedstock-extraction build_improvement priority '
    '(Refs #2847 H8-extraction)',
    () {
      test(
        'supplier gate active: the emitted build_improvement suggestion '
        'targets the unimproved timber feedstock tile, not the lex-first grain '
        'tile',
        () {
          final game = _game();
          // Precondition: the supplier-side feedstock gate is active.
          expect(
            feedstockExtractionResourceIdsForPlayer(game, _supplierId),
            containsAll(<String>['timber', 'iron']),
          );

          final improvements = _buildImprovementSuggestions(game);
          expect(improvements, isNotEmpty);
          expect(
            improvements.map((o) => o.targetTileKey),
            contains(_supplierTimberTile),
            reason:
                'feedstock-priority ordering must surface the timber tile as a '
                'build_improvement suggestion',
          );
          // The single emitted suggestion is the feedstock tile (the pipeline
          // emits only the first accepted candidate per Builder per target).
          expect(improvements.single.targetTileKey, _supplierTimberTile);
        },
      );

      test(
        'supplier gate inactive (peer at quota): ordinary lexicographic '
        'ordering emits the grain tile (negative control)',
        () {
          final game = _game(
            sellerOw: kObserverConquestMinOwProvincesPerGp,
            supplierCastIron: 10,
          );
          // Precondition: no peer needs the improvement input → gate empty.
          expect(
            feedstockExtractionResourceIdsForPlayer(game, _supplierId),
            isEmpty,
          );

          final improvements = _buildImprovementSuggestions(game);
          expect(improvements, isNotEmpty);
          expect(improvements.single.targetTileKey, _supplierGrainTile);
        },
      );

      test(
        'supplier with lumber only: feedstock build_improvement is accepted '
        'under castIron waiver',
        () {
          final game = _game();
          expect(
            feedstockBootstrapBuildImprovementCastIronWaived(
              game,
              _supplierId,
              _supplierTimberTile,
            ),
            isTrue,
          );
          final improvements = _buildImprovementSuggestions(game);
          expect(improvements.single.targetTileKey, _supplierTimberTile);
        },
      );

      test('suggestion ordering is deterministic across repeated passes', () {
        final game = _game();
        final first = _buildImprovementSuggestions(game)
            .map((o) => o.targetTileKey)
            .toList();
        final second = _buildImprovementSuggestions(game)
            .map((o) => o.targetTileKey)
            .toList();
        expect(first, equals(second));
        expect(first.single, _supplierTimberTile);
      });

      // Refs #3393 Phase 6b (slice 5) — `_newWorldProvinceCountOwnedBy` now
      // reads `ProvinceOwnerCache.countOwnedByInRegion(playerId,
      // kRegionNewWorld)`. The non-zero branch must still short-circuit the
      // zero-NW lock-recovery seller gate: when the seller owns a New World
      // province, the peer-supplier feedstock gate deactivates (negative
      // control proving the migrated count is behaviour-preserving).
      test(
        'seller owning a New World province deactivates the feedstock gate '
        '(projection-backed new-world count)',
        () {
          // Sanity: zero New World provinces keeps the gate active.
          expect(
            feedstockExtractionResourceIdsForPlayer(_game(), _supplierId),
            containsAll(<String>['timber', 'iron']),
          );

          final game = _game(sellerNw: 1);
          expect(
            feedstockExtractionResourceIdsForPlayer(game, _supplierId),
            isEmpty,
            reason:
                'a below-quota seller owning a New World province is no longer '
                'a zero-NW lock-recovery seller, so the peer-supplier gate '
                'must empty',
          );
        },
      );
    },
  );

  group(
    'suggestWorkOrders feedstock co-availability ordering '
    '(Refs #2847 H8-extraction feedstock co-availability)',
    () {
      test(
        'supplier holds timber but no iron: the emitted build_improvement '
        'suggestion targets the least-held iron tile, not the lex-first timber '
        'tile',
        () {
          final game = _coAvailGame(supplierTimberHeld: 13, supplierIronHeld: 0);
          // Precondition: the supplier-side feedstock gate covers timber + iron.
          expect(
            feedstockExtractionResourceIdsForPlayer(game, _supplierId),
            containsAll(<String>['timber', 'iron']),
          );

          final improvements = _buildImprovementSuggestions(game);
          expect(improvements, isNotEmpty);
          // The single emitted suggestion is the least-held feedstock (iron),
          // even though the timber tile sorts lexicographically first.
          expect(
            improvements.single.targetTileKey,
            _coAvailIronTile,
            reason:
                'co-availability ordering must surface the missing co-feedstock '
                '(iron) ahead of the already-held timber tile',
          );
        },
      );

      test(
        'supplier holds equal feedstock (zero of each): lexicographic tie-break '
        'emits the timber tile (negative control)',
        () {
          final game = _coAvailGame(supplierTimberHeld: 0, supplierIronHeld: 0);
          final improvements = _buildImprovementSuggestions(game);
          expect(improvements, isNotEmpty);
          // Held timber == held iron == 0 → tie-break by tile key, and the
          // timber tile key sorts before the iron tile key.
          expect(improvements.single.targetTileKey, _coAvailTimberTile);
        },
      );

      test('co-availability ordering is deterministic across repeated passes', () {
        final game = _coAvailGame(supplierTimberHeld: 13, supplierIronHeld: 0);
        final first = _buildImprovementSuggestions(game)
            .map((o) => o.targetTileKey)
            .toList();
        final second = _buildImprovementSuggestions(game)
            .map((o) => o.targetTileKey)
            .toList();
        expect(first, equals(second));
        expect(first.single, _coAvailIronTile);
      });
    },
  );
}
