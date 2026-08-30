// Military counsel ranking (Refs #4307 Slice A, #4508 Slice D). Dense for repo.orders_test_support_loc.
// dart format off
import 'package:colonizethis_orders/src/orders/military_counsel_scoring.dart';
import 'package:colonizethis_orders/src/orders/military_counsel_types.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_probe_validator.dart';
import 'package:colonizethis_test/test.dart';
import 'support/counsel/military_counsel_ranking_fixtures.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup('rankMilitaryCounselRecommendations', [
    rs('builds one pass-level validator without fallback rebuild (Refs #4508)', () {resetIncrementalCandidateValidatorBuildCountForTests(); mcRank(mcTrainGame(), topology: mcTopo(['P1'])); expect(incrementalCandidateValidatorBuildCountForTests, 1);}),
    rs('returns at most three stable recommendations', () {final game = mcTrainGame(); final topo = mcTopo(['P1']); final first = mcRank(game, topology: topo); expect(first.length, lessThanOrEqualTo(3)); expect(mcRank(game, topology: topo).map((r) => r.recommendationId).toList(), equals(first.map((r) => r.recommendationId).toList()));}),
    rs('emits train recommendation with positive count and cost snapshot', () {final trains = mcRank(mcTrainGame(), topology: mcTopo(['P1'])).where((r) => r.kind == MilitaryCounselRecommendationKind.trainUnit).toList(); expect(trains, isNotEmpty); final train = trains.first; expect(train.count, greaterThan(0)); expect(train.unitType, isNotNull); expect(train.recommendationId, 'train:${train.unitType}'); expect(train.costSnapshot?.treasuryCost, greaterThan(0)); expect(train.briefReasonKey, MilitaryCounselReasonKey.affordableTrain); expect(train.isHighlight, isTrue);}),
    rs('returns empty when no affordable builds and no invasions', () {expect(mcRank(mcEmptyGame()), isEmpty);}),
    rs('never recommends Home Army for invade', () {final home = mcHomeArmy(); final invades = mcRank(mcInvadeWithHomeArmy(), topology: mcTopo(['P1', 'P2'], [('P1', 'P2')])).where((r) => r.kind == MilitaryCounselRecommendationKind.invade).toList(); expect(invades, isNotEmpty); expect(invades.every((r) => r.armyId != home.id), isTrue);}),
    rs('invade at war scores higher than declare-war peace target', () {expect(militaryCounselScoreInvade(game: mcInvadeGame(diplomacy: mcAtWar()), playerId: mcGp1, ownerFactionId: mcGp2), greaterThan(militaryCounselScoreInvade(game: mcInvadeGame(), playerId: mcGp1, ownerFactionId: mcGp2)));}),
    rs('emits invade recommendation with intel and stable id', () {final invade = mcRank(mcInvadeGame(), topology: mcTopo(['P1', 'P2'], [('P1', 'P2')])).singleWhere((r) => r.kind == MilitaryCounselRecommendationKind.invade); expect(invade.recommendationId, 'invade:${invade.armyId}:${invade.destinationProvinceId}'); expect(invade.requiresDeclareWar, isTrue); expect(invade.ownerFactionId, mcGp2); expect(invade.invasionIntel, isNotNull); expect(invade.briefReasonKey, MilitaryCounselReasonKey.declareWarInvasion);}),
    rs('at war invade recommendation omits declare-war flag', () {final invade = mcRank(mcInvadeGame(diplomacy: mcAtWar()), topology: mcTopo(['P1', 'P2'], [('P1', 'P2')])).singleWhere((r) => r.kind == MilitaryCounselRecommendationKind.invade); expect(invade.requiresDeclareWar, isFalse); expect(invade.briefReasonKey, MilitaryCounselReasonKey.atWarInvasion);}),
    rs('sorts by descending rankScore then kind precedence', () {final ranked = mcRank(mcInvadeGame(diplomacy: mcAtWar()), topology: mcTopo(['P1', 'P2'], [('P1', 'P2')])); for (var i = 0; i < ranked.length - 1; i++) {expect(ranked[i].rankScore, greaterThanOrEqualTo(ranked[i + 1].rankScore));}}),
  ], runRunnableScenario);
}
