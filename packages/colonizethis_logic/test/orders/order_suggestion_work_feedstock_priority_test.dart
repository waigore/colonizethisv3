import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
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
Game _game({int sellerOw = 5}) {
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
    newWorld: const RegionData(),
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
        // Affordable build_improvement (level-0 cost {lumber: 1, castIron: 1}).
        stockpile: const Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
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
          final game = _game(sellerOw: kObserverConquestMinOwProvincesPerGp);
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
    },
  );
}
