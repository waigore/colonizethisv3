import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _playerId = 'gp1';
const _tileGrain = 'oldWorld|p0|0|0';
const _tileTimber = 'oldWorld|p0|2|0';

/// A below-quota zero-NW lock-recovery seller whose **fabric** improvement-cost
/// gate is inactive (it owns no unimproved `wool` / `cotton` tile) but which
/// still owns a `castIron`-feedstock (`timber`) tile — the seed-42 gp5 profile
/// after its fabric feedstock tile has been improved. Refs #2847 § H8
/// production allocation (S7-D castIron production-assignment, PR #3289).
Game _stageableSellerGame({
  int owOwned = 5,
  int nwOwned = 0,
  Stockpile stockpile = const Stockpile(),
  List<Unit> extraUnits = const [],
  Map<String, String> resourceByTileKey = const {
    _tileGrain: 'grain',
    _tileTimber: 'timber',
  },
}) {
  final owProvinces = List.generate(
    owOwned,
    (i) => Province(
      id: 'oldWorld|p$i',
      regionId: kRegionOldWorld,
      ownerId: _playerId,
    ),
  );
  final nwProvinces = List.generate(
    nwOwned,
    (i) => Province(
      id: 'newWorld|n$i',
      regionId: kRegionNewWorld,
      ownerId: _playerId,
    ),
  );
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: owProvinces, units: extraUnits),
      newWorld: RegionData(provinces: nwProvinces),
      resourceByTileKey: resourceByTileKey,
      tileState: TileMapState(),
    ),
    players: [
      Player(
        id: _playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: stockpile,
      ),
    ],
  );
}

void main() {
  group(
    'selfLockRecoverySellerStageableImprovementInputs '
    '(Refs #2847 H8 production allocation — S7-D castIron, PR #3289)',
    () {
      test(
        'lock-recovery seller short castIron that owns a timber tile but no '
        'unimproved fabric tile returns only the multi-input castIron',
        () {
          // The seller owns a `timber` tile (so it extracts castIron feedstock)
          // but no `wool` / `cotton` tile, so the fabric improvement-cost gate
          // is inactive and the prior self-need helper is empty here.
          final game = _stageableSellerGame();
          expect(
            selfLockRecoverySellerNeededProducibleImprovementInputs(
              game,
              _playerId,
            ),
            isEmpty,
            reason: 'fabric-tile gate inactive: prior helper must be empty',
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, _playerId),
            equals({CommodityCatalog.castIron.id}),
            reason:
                'castIron is the only producible multi-input level-0 input; '
                'single-input lumber is excluded',
          );
        },
      );

      test(
        'returns empty when the seller owns no castIron feedstock tile '
        '(negative control — gate-inactive sellers with no tile do not stage)',
        () {
          final game = _stageableSellerGame(
            resourceByTileKey: const {_tileGrain: 'grain'},
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, _playerId),
            isEmpty,
          );
        },
      );

      test(
        'returns empty when the seller already holds castIron (short check)',
        () {
          final game = _stageableSellerGame(
            stockpile: const Stockpile().applyDelta(
              CommodityCatalog.castIron.id,
              1,
            ),
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, _playerId),
            isEmpty,
          );
        },
      );

      test(
        'returns empty when the GP already owns a regiment '
        '(negative control — +6 baseline GPs unaffected)',
        () {
          final game = _stageableSellerGame(
            extraUnits: [
              Unit(
                id: 'r1',
                type: 'peasant_levies',
                ownerId: _playerId,
                locationProvinceId: 'oldWorld|p0',
              ),
            ],
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, _playerId),
            isEmpty,
          );
        },
      );

      test(
        'returns empty at the conquest quota (negative control)',
        () {
          final game = _stageableSellerGame(
            owOwned: kObserverConquestMinOwProvincesPerGp,
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, _playerId),
            isEmpty,
          );
        },
      );

      test(
        'returns empty when the seller owns a New World province '
        '(negative control — only zero-NW sellers stage)',
        () {
          final game = _stageableSellerGame(nwOwned: 1);
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, _playerId),
            isEmpty,
          );
        },
      );

      test('returns empty for an unknown player id', () {
        final game = _stageableSellerGame();
        expect(
          selfLockRecoverySellerStageableImprovementInputs(
            game,
            'no_such_player',
          ),
          isEmpty,
        );
      });
    },
  );
}
