// Development counsel ranking (Refs #4332 Slice 2, #4508 Slice D).
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/development_counsel_types.dart';
import 'package:colonizethis_orders/src/orders/engineer_work_scoring.dart';
import 'package:colonizethis_test/test.dart';
import 'support/counsel/development_counsel_ranking_fixtures.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup('engineerWorkScore / bestEngineerWorkOrder', [
    rs('resource port beats plain port', () {expect(bestEngineerWorkOrder([dcEng(dcBuildPort, dcPortPlain), dcEng(dcBuildPort, dcPortResource)], dcGame(resourceByTileKey: const {dcPortResource: 'iron'}), playerId: dcGp1)?.targetTileKey, dcPortResource);}, '#4332'),
    rs('resource road beats plain fort (unified pool)', () {final best = bestEngineerWorkOrder([dcEng(dcBuildFort, dcPortPlain), dcEng(dcBuildRoad, dcPortResource)], dcGame(resourceByTileKey: const {dcPortResource: 'coal'}), playerId: dcGp1); expect(best?.target, dcBuildRoad); expect(best?.targetTileKey, dcPortResource);}, '#4332'),
  ], runRunnableScenario);
  runLabeledScenarioGroup('rankDevelopmentCounselRecommendationsFromSuggestions', [
    rs('emits build_port when port wins Engineer pool', () {final ranked = dcRank(dcGame(resourceByTileKey: const {dcPortPlain: 'grain'}), [dcEng(dcBuildPort, dcPortPlain), dcEng(dcBuildFort, dcPortResource)]); expect(ranked, hasLength(1)); expect(ranked.single.kind, DevelopmentCounselRecommendationKind.buildPort); expect(ranked.single.targetTileKey, dcPortPlain); expect(ranked.single.briefReasonKey, DevelopmentCounselReasonKey.resourceCoast); expect(ranked.single.provinceDisplayName, 'Harbor'); expect(ranked.single.isHighlight, isTrue);}, '#4332'),
    rs('omits port when road outscores port', () {expect(dcRank(dcGame(resourceByTileKey: const {dcPortResource: 'coal'}), [dcEng(dcBuildPort, dcPortPlain), dcEng(dcBuildRoad, dcPortResource)]), isEmpty);}, '#4332'),
    rs('empty suggestions yield empty counsel', () {expect(dcRank(dcGame(), const []), isEmpty);}, '#4332'),
    rs('newWorldCoast reason when NW port wins without resource', () {final ranked = dcRank(dcGame(regionId: kNewWorldRegionId), [dcEng(dcBuildPort, dcNwPort)]); expect(ranked, hasLength(1)); expect(ranked.single.briefReasonKey, DevelopmentCounselReasonKey.newWorldCoast);}, '#4332'),
  ], runRunnableScenario);
}
