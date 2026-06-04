import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847 § H8-extraction supplier feedstock. Two-player fixture: an
// above-quota affluent supplier (`_supplierId`) and a below-quota zero-NW
// lock-recovery seller (`_sellerId`) that needs the `castIron` improvement
// input but holds none. The supplier owns an unimproved `timber` tile (and a
// `grain` tile) so the supplier-side extraction gate can route its Builder.
const _supplierId = 'gp1';
const _sellerId = 'gp2';

// The grain tile key is lexicographically smaller than the timber tile key, so
// ordinary build-improvement ordering (equal base score, lexicographic
// tie-break) selects grain; only the active feedstock score boost flips the
// supplier's Builder onto the timber tile.
const _supplierGrainTile = 'oldWorld|s0|0|0';
const _supplierTimberTile = 'oldWorld|s0|1|0';
const _sellerWoolTile = 'oldWorld|p0|0|0';

/// Builds a game with a supplier owning [supplierOw] Old World provinces and a
/// seller owning [sellerOw] Old World provinces. The seller is configured (by
/// default) as an active below-quota zero-NW lock-recovery seller that needs
/// the `castIron` improvement input: recovered treasury, zero regiments, no
/// `fabric`, `lumber` on hand (so only the `castIron` improvement input is
/// missing) and an unimproved `wool` feedstock tile.
Game _twoPlayerGame({
  int supplierOw = kObserverConquestMinOwProvincesPerGp,
  int sellerOw = 5,
  int sellerTreasury = -1,
  Stockpile sellerStockpile = const Stockpile(quantities: {'lumber': 1}),
  Map<String, String> resourceByTileKey = const {
    _supplierTimberTile: 'timber',
    _supplierGrainTile: 'grain',
    _sellerWoolTile: 'wool',
  },
  TileMapState? tileState,
  List<Unit> extraUnits = const [],
}) {
  final treasury = sellerTreasury < 0
      ? cheapestRegimentBuildTreasuryCost()
      : sellerTreasury;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|s$i',
        regionId: kRegionOldWorld,
        ownerId: _supplierId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|p$i',
        regionId: kRegionOldWorld,
        ownerId: _sellerId,
      ),
  ];
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: extraUnits),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState ?? TileMapState(),
    ),
    players: [
      Player(
        id: _supplierId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        // Supplier holds no timber/iron surplus — it must extract more.
        stockpile: const Stockpile(),
      ),
      Player(
        id: _sellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: treasury,
        stockpile: sellerStockpile,
      ),
    ],
  );
}

PlayerView _supplierBuilderView(Game game) {
  return PlayerView(
    playerId: _supplierId,
    player: game.players.firstWhere((p) => p.id == _supplierId),
    ownUnitsById: {
      'b1': Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: _supplierId,
        locationProvinceId: 'oldWorld|s0',
      ),
    },
    provincesById: const {},
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

void main() {
  group(
    'supplierImprovementInputFeedstockExtractionResourceIds '
    '(Refs #2847 H8-extraction supplier feedstock)',
    () {
      test('active peer demand returns castIron feedstock {timber, iron}', () {
        final game = _twoPlayerGame();
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            _supplierId,
          ),
          containsAll(<String>['timber', 'iron']),
        );
      });

      test('returns empty for a player that is itself a locked seller', () {
        final game = _twoPlayerGame();
        // The seller's own feedstock-extraction gate routes its Builder; the
        // supplier role must exclude it.
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            _sellerId,
          ),
          isEmpty,
        );
      });

      test('returns empty when no peer needs the improvement input', () {
        // Seller at quota → not a below-quota lock-recovery seller, so no peer
        // demand exists.
        final game = _twoPlayerGame(sellerOw: kObserverConquestMinOwProvincesPerGp);
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            _supplierId,
          ),
          isEmpty,
        );
      });

      test('returns empty when the peer already holds castIron', () {
        final game = _twoPlayerGame(
          sellerStockpile: const Stockpile(
            quantities: {'lumber': 1, 'castIron': 1},
          ),
        );
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            _supplierId,
          ),
          isEmpty,
        );
      });

      test('returns empty when the supplier owns no unimproved feedstock tile', () {
        final game = _twoPlayerGame(
          resourceByTileKey: const {
            _supplierGrainTile: 'grain',
            _sellerWoolTile: 'wool',
          },
        );
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            _supplierId,
          ),
          isEmpty,
        );
      });

      test('returns empty when the supplier feedstock tile is already improved', () {
        final game = _twoPlayerGame(
          tileState: TileMapState().setImprovement(_supplierTimberTile, 1),
        );
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            _supplierId,
          ),
          isEmpty,
        );
      });

      test('evaluation is deterministic', () {
        final game = _twoPlayerGame();
        final a = supplierImprovementInputFeedstockExtractionResourceIds(
          game,
          _supplierId,
        );
        final b = supplierImprovementInputFeedstockExtractionResourceIds(
          game,
          _supplierId,
        );
        expect(a, equals(b));
      });
    },
  );

  group(
    'selectFullAiCivilianWorkOrders supplier feedstock extraction '
    '(Refs #2847 H8-extraction supplier feedstock)',
    () {
      test('supplier Builder prefers timber feedstock tile over grain', () {
        final game = _twoPlayerGame();
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _supplierGrainTile,
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _supplierTimberTile,
          ),
        ];
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: _supplierBuilderView(game),
          game: game,
        );
        expect(r.workOrders, hasLength(1));
        expect(r.workOrders.single.targetTileKey, _supplierTimberTile);
      });

      test('supplier keeps ordinary ordering when no peer needs the input', () {
        final game = _twoPlayerGame(
          sellerOw: kObserverConquestMinOwProvincesPerGp,
        );
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _supplierGrainTile,
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _supplierTimberTile,
          ),
        ];
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: _supplierBuilderView(game),
          game: game,
        );
        // No supplier feedstock boost → ordinary deterministic ordering
        // (lexicographically smaller grain tile key wins the tie).
        expect(r.workOrders.single.targetTileKey, _supplierGrainTile);
      });

      test('selection is deterministic when the supplier gate is active', () {
        final game = _twoPlayerGame();
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _supplierGrainTile,
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _supplierTimberTile,
          ),
        ];
        final view = _supplierBuilderView(game);
        final a = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: view,
          game: game,
        );
        final b = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: view,
          game: game,
        );
        expect(a.workOrders, equals(b.workOrders));
      });
    },
  );

  group(
    'selectFullAiCivilianWorkOrders mineral feedstock prospecting '
    '(Refs #2847 H8-extraction mineral feedstock prospecting)',
    () {
      const supplierIronTile = 'oldWorld|s0|2|0';
      const exploreTile = 'oldWorld|s1|0|0';

      Game ironGame({bool ironProspected = false, int sellerOw = 5}) {
        return _twoPlayerGame(
          sellerOw: sellerOw,
          resourceByTileKey: const {
            _supplierTimberTile: 'timber',
            _supplierGrainTile: 'grain',
            supplierIronTile: 'iron',
            _sellerWoolTile: 'wool',
          },
        ).copyWithProspected(
          ironProspected ? const {supplierIronTile} : const {},
        );
      }

      PlayerView explorerView(Game game) => PlayerView(
            playerId: _supplierId,
            player: game.players.firstWhere((p) => p.id == _supplierId),
            ownUnitsById: {
              'e1': Unit(
                id: 'e1',
                type: kUnitTypeExplorer,
                ownerId: _supplierId,
                locationProvinceId: 'oldWorld|s0',
              ),
            },
            provincesById: const {},
            visibilityByTile: const {},
            prospectedTiles: const {},
            diplomacyByOtherId: const {},
          );

      List<WorkOrder> suggestions() => const [
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: exploreTile,
            ),
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetProspect,
              targetTileKey: supplierIronTile,
            ),
          ];

      test(
        'supplier gate active: Explorer prospects the unprospected iron '
        'feedstock tile ahead of exploring',
        () {
          final game = ironGame();
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions(),
            view: explorerView(game),
            game: game,
          );
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.target, kWorkTargetProspect);
          expect(r.workOrders.single.targetTileKey, supplierIronTile);
        },
      );

      test(
        'iron tile already prospected: no prospect boost, Explorer explores '
        '(negative control)',
        () {
          final game = ironGame(ironProspected: true);
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions(),
            view: explorerView(game),
            game: game,
          );
          expect(r.workOrders.single.target, kWorkTargetExplore);
        },
      );

      test(
        'supplier gate inactive (peer at quota): no prospect boost, Explorer '
        'explores (negative control)',
        () {
          final game = ironGame(
            sellerOw: kObserverConquestMinOwProvincesPerGp,
          );
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions(),
            view: explorerView(game),
            game: game,
          );
          expect(r.workOrders.single.target, kWorkTargetExplore);
        },
      );

      test('prospect selection is deterministic across repeated passes', () {
        final game = ironGame();
        final view = explorerView(game);
        final a = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions(),
          view: view,
          game: game,
        );
        final b = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions(),
          view: view,
          game: game,
        );
        expect(a.workOrders, equals(b.workOrders));
        expect(a.workOrders.single.targetTileKey, supplierIronTile);
      });
    },
  );
}

extension _ProspectedGame on Game {
  /// Returns a copy of this game with [_supplierId]'s prospected-tile set
  /// replaced by [tiles] (test helper for mineral feedstock prospecting).
  Game copyWithProspected(Set<String> tiles) {
    return Game(
      id: id,
      worldState: WorldState(
        turnState: worldState.turnState,
        oldWorld: worldState.oldWorld,
        newWorld: worldState.newWorld,
        resourceByTileKey: worldState.resourceByTileKey,
        tileState: worldState.tileState,
        playerProspectedTiles: {_supplierId: tiles},
      ),
      players: players,
    );
  }
}
