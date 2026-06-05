import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _playerId = 'gp1';
const _tileGrain = 'oldWorld|p0|0|0';
const _tileWool = 'oldWorld|p0|1|0';

Game _belowQuotaZeroNwSellerGame({
  required int owOwned,
  required int treasury,
  Stockpile stockpile = const Stockpile(),
  List<Unit> extraUnits = const [],
  Map<String, String> resourceByTileKey = const {
    _tileGrain: 'grain',
    _tileWool: 'wool',
  },
  TileMapState? tileState,
}) {
  final provinces = List.generate(
    owOwned,
    (i) => Province(
      id: 'oldWorld|p$i',
      regionId: kRegionOldWorld,
      ownerId: _playerId,
    ),
  );
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
        id: _playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: treasury,
        stockpile: stockpile,
      ),
    ],
  );
}

void main() {
  group(
    'selfLockRecoverySellerNeededProducibleImprovementInputs '
    '(Refs #2847 H8-extraction S7-D lumber re-localization)',
    () {
      test(
        'active gate + short of both lumber and castIron returns both '
        'producible level-0 inputs',
        () {
          // Default empty stockpile: the seller holds neither lumber nor
          // castIron, and both are producible (lumber from timber; castIron
          // from timber + iron), so both join the seller-side domestic
          // production set.
          final game = _belowQuotaZeroNwSellerGame(
            owOwned: 5,
            treasury: cheapestRegimentBuildTreasuryCost(),
          );
          expect(
            selfLockRecoverySellerNeededProducibleImprovementInputs(
              game,
              _playerId,
            ),
            equals({CommodityCatalog.lumber.id, CommodityCatalog.castIron.id}),
          );
        },
      );

      test(
        'an input the seller already holds is excluded (only the binding '
        'lumber remains when castIron is on hand)',
        () {
          final game = _belowQuotaZeroNwSellerGame(
            owOwned: 5,
            treasury: cheapestRegimentBuildTreasuryCost(),
            stockpile: const Stockpile().applyDelta(
              CommodityCatalog.castIron.id,
              1,
            ),
          );
          expect(
            selfLockRecoverySellerNeededProducibleImprovementInputs(
              game,
              _playerId,
            ),
            equals({CommodityCatalog.lumber.id}),
          );
        },
      );

      test(
        'returns empty when the gate is inactive (at conquest quota) — '
        'negative control, +6 baseline GPs unaffected',
        () {
          final game = _belowQuotaZeroNwSellerGame(
            owOwned: kObserverConquestMinOwProvincesPerGp,
            treasury: cheapestRegimentBuildTreasuryCost(),
          );
          expect(
            selfLockRecoverySellerNeededProducibleImprovementInputs(
              game,
              _playerId,
            ),
            isEmpty,
          );
        },
      );

      test(
        'returns empty when the GP already owns a regiment '
        '(negative control)',
        () {
          final game = _belowQuotaZeroNwSellerGame(
            owOwned: 5,
            treasury: cheapestRegimentBuildTreasuryCost(),
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
            selfLockRecoverySellerNeededProducibleImprovementInputs(
              game,
              _playerId,
            ),
            isEmpty,
          );
        },
      );

      test('returns empty for an unknown player id', () {
        final game = _belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
        );
        expect(
          selfLockRecoverySellerNeededProducibleImprovementInputs(
            game,
            'no_such_player',
          ),
          isEmpty,
        );
      });
    },
  );
}
