// Development counsel ranking (Refs #4332 Slice 2).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/development_counsel_ranking.dart';
import 'package:colonizethis_orders/src/orders/development_counsel_types.dart';
import 'package:colonizethis_orders/src/orders/engineer_work_scoring.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'support/scenario_runner.dart';

const _ow = 'oldWorld';
const _gp1 = 'gp1';

WorkOrder _eng(String target, String tile, {String unitId = 'e1'}) =>
    WorkOrder(unitId: unitId, target: target, targetTileKey: tile);

Game _game({
  Map<String, String> resourceByTileKey = const {},
  String? capitalProvinceId,
  String regionId = _ow,
}) {
  return TestFixtures.minimalGame(
    id: 'g-dev-counsel',
    turnNumber: 1,
    players: [
      Player(
        id: _gp1,
        displayName: 'GP',
        isHuman: true,
        capitalProvinceId: capitalProvinceId ?? '$_ow|P1',
      ),
    ],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$_ow|P1',
          regionId: _ow,
          ownerId: _gp1,
          displayName: 'Harbor',
        ),
        Province(id: '$_ow|P2', regionId: _ow, ownerId: _gp1),
      ],
    ),
    newWorld: regionId == kNewWorldRegionId
        ? RegionData(
            provinces: [
              Province(
                id: '$kNewWorldRegionId|P1',
                regionId: kNewWorldRegionId,
                ownerId: _gp1,
                displayName: 'NW Coast',
              ),
            ],
          )
        : null,
    resourceByTileKey: resourceByTileKey,
  );
}

void main() {
  runLabeledScenarioGroup('engineerWorkScore / bestEngineerWorkOrder', [
    rs('resource port beats plain port', () {
      const portResource = '$_ow|P1|1|0';
      const portPlain = '$_ow|P1|0|0';
      final game = _game(resourceByTileKey: const {portResource: 'iron'});
      final best = bestEngineerWorkOrder(
        [
          _eng(kWorkTargetBuildPort, portPlain),
          _eng(kWorkTargetBuildPort, portResource),
        ],
        game,
        playerId: _gp1,
      );
      expect(best?.targetTileKey, portResource);
    }, '#4332'),
    rs('resource road beats plain fort (unified pool)', () {
      const roadTile = '$_ow|P1|1|0';
      const fortTile = '$_ow|P1|0|0';
      final game = _game(resourceByTileKey: const {roadTile: 'coal'});
      final best = bestEngineerWorkOrder(
        [
          _eng(kWorkTargetBuildFort, fortTile),
          _eng(kWorkTargetBuildRoad, roadTile),
        ],
        game,
        playerId: _gp1,
      );
      expect(best?.target, kWorkTargetBuildRoad);
      expect(best?.targetTileKey, roadTile);
    }, '#4332'),
  ], runRunnableScenario);

  runLabeledScenarioGroup(
    'rankDevelopmentCounselRecommendationsFromSuggestions',
    [
      rs('emits build_port when port wins Engineer pool', () {
        const portTile = '$_ow|P1|0|0';
        final game = _game(resourceByTileKey: const {portTile: 'grain'});
        final ranked = rankDevelopmentCounselRecommendationsFromSuggestions(
          game: game,
          playerId: _gp1,
          workSuggestions: [
            _eng(kWorkTargetBuildPort, portTile),
            _eng(kWorkTargetBuildFort, '$_ow|P1|1|0'),
          ],
        );
        expect(ranked, hasLength(1));
        expect(
          ranked.single.kind,
          DevelopmentCounselRecommendationKind.buildPort,
        );
        expect(ranked.single.targetTileKey, portTile);
        expect(
          ranked.single.briefReasonKey,
          DevelopmentCounselReasonKey.resourceCoast,
        );
        expect(ranked.single.provinceDisplayName, 'Harbor');
        expect(ranked.single.isHighlight, isTrue);
      }, '#4332'),
      rs('omits port when road outscores port', () {
        const portTile = '$_ow|P1|0|0';
        const roadTile = '$_ow|P1|1|0';
        final game = _game(resourceByTileKey: const {roadTile: 'coal'});
        final ranked = rankDevelopmentCounselRecommendationsFromSuggestions(
          game: game,
          playerId: _gp1,
          workSuggestions: [
            _eng(kWorkTargetBuildPort, portTile),
            _eng(kWorkTargetBuildRoad, roadTile),
          ],
        );
        expect(ranked, isEmpty);
      }, '#4332'),
      rs('empty suggestions yield empty counsel', () {
        final ranked = rankDevelopmentCounselRecommendationsFromSuggestions(
          game: _game(),
          playerId: _gp1,
          workSuggestions: const [],
        );
        expect(ranked, isEmpty);
      }, '#4332'),
      rs('newWorldCoast reason when NW port wins without resource', () {
        const portTile = '$kNewWorldRegionId|P1|0|0';
        final game = _game(regionId: kNewWorldRegionId);
        final ranked = rankDevelopmentCounselRecommendationsFromSuggestions(
          game: game,
          playerId: _gp1,
          workSuggestions: [_eng(kWorkTargetBuildPort, portTile)],
        );
        expect(ranked, hasLength(1));
        expect(
          ranked.single.briefReasonKey,
          DevelopmentCounselReasonKey.newWorldCoast,
        );
      }, '#4332'),
    ],
    runRunnableScenario,
  );
}
