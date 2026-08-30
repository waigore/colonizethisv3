// Development counsel ranking Game/work fixtures (Refs #4508 Slice D).
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/development_counsel_ranking.dart';
import 'package:colonizethis_orders/src/orders/development_counsel_types.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const dcOw = 'oldWorld';
const dcGp1 = 'gp1';

WorkOrder dcEng(String target, String tile, {String unitId = 'e1'}) => WorkOrder(unitId: unitId, target: target, targetTileKey: tile);

Game dcGame({Map<String, String> resourceByTileKey = const {}, String? capitalProvinceId, String regionId = dcOw}) => TestFixtures.minimalGame(id: 'g-dev-counsel', turnNumber: 1, players: [Player(id: dcGp1, displayName: 'GP', isHuman: true, capitalProvinceId: capitalProvinceId ?? '$dcOw|P1')], oldWorld: RegionData(provinces: [Province(id: '$dcOw|P1', regionId: dcOw, ownerId: dcGp1, displayName: 'Harbor'), Province(id: '$dcOw|P2', regionId: dcOw, ownerId: dcGp1)]), newWorld: regionId == kNewWorldRegionId ? RegionData(provinces: [Province(id: '$kNewWorldRegionId|P1', regionId: kNewWorldRegionId, ownerId: dcGp1, displayName: 'NW Coast')]) : null, resourceByTileKey: resourceByTileKey);

List<DevelopmentCounselRecommendation> dcRank(Game game, List<WorkOrder> workSuggestions) => rankDevelopmentCounselRecommendationsFromSuggestions(game: game, playerId: dcGp1, workSuggestions: workSuggestions);

const dcPortPlain = '$dcOw|P1|0|0';
const dcPortResource = '$dcOw|P1|1|0';
const dcNwPort = '$kNewWorldRegionId|P1|0|0';
const dcBuildPort = kWorkTargetBuildPort;
const dcBuildFort = kWorkTargetBuildFort;
const dcBuildRoad = kWorkTargetBuildRoad;
