// Table-driven recruit-worker suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_recruit_worker_fixtures.dart';
import 'order_suggestion_recruit_worker_test_support.dart';
// dart format off

void osrwRunReturnsPeasantAndApprenticeWhenSupported() {final game = recruitWorkerInclusionPeasantAndApprenticeGame(); final list = suggestRecruitWorkerOrders(recruitWorkerTestViewFor(game,'p1'),game,recruitWorkerTestTopology,const Orders(),); expect(list.map((o) => o.targetTier),containsAllInOrder(<WorkerTier>[WorkerTier.peasant,WorkerTier.apprentice]),); expect(list.any((o) => o.targetTier == WorkerTier.journeyman),isFalse,reason: 'journeyman tech is locked',); expect(list.any((o) => o.targetTier == WorkerTier.master),isFalse,reason: 'master tech is locked',); for (final candidate in list) {expect(recruitWorkerTestEngineAccepts(game,const Orders(),'p1',candidate),isTrue,reason: 'engine round-trip must accept emitted candidate ' '${candidate.targetTier.name} per SPEC equivalence guarantee',); }}

void osrwRunOmitsTrainedTiersWhenTechsLocked() {final game = recruitWorkerInclusionTechLockedGame(); final list = suggestRecruitWorkerOrders(recruitWorkerTestViewFor(game,'p1'),game,recruitWorkerTestTopology,const Orders(),); expect(list.map((o) => o.targetTier).toList(),[WorkerTier.peasant]); for (final tier in recruitWorkerTestAllTiers.where((t) => t != WorkerTier.peasant,)) {final candidate = RecruitWorkerOrder(targetTier: tier); expect(recruitWorkerTestEngineAccepts(game,const Orders(),'p1',candidate),isFalse,reason: '${tier.name} candidate rejected at the order engine ' 'because tech gate is locked',); }}

void osrwRunOmitsPeasantWhenFabricInsufficient() {final game = recruitWorkerInclusionInsufficientFabricGame(); final list = suggestRecruitWorkerOrders(recruitWorkerTestViewFor(game,'p1'),game,recruitWorkerTestTopology,const Orders(),); expect(list.any((o) => o.targetTier == WorkerTier.peasant),isFalse,reason: 'peasant row needs 2 fabric',);}

void osrwRunOmitsApprenticeWhenTreasuryBelow200() {final game = recruitWorkerInclusionLowTreasuryGame(); final list = suggestRecruitWorkerOrders(recruitWorkerTestViewFor(game,'p1'),game,recruitWorkerTestTopology,const Orders(),); expect(list.any((o) => o.targetTier == WorkerTier.apprentice),isFalse,reason: 'apprentice row needs 200 ducats; treasury == 100',);}

void osrwRunOmitsApprenticeWhenPeasantPoolEmpty() {final game = recruitWorkerInclusionEmptyPeasantPoolGame(); final list = suggestRecruitWorkerOrders(recruitWorkerTestViewFor(game,'p1'),game,recruitWorkerTestTopology,const Orders(),); expect(list.any((o) => o.targetTier == WorkerTier.apprentice),isFalse,reason: 'apprentice row consumes 1 peasant',);}

void osrwRunReturnsAllFourTiersWhenFullyUnlocked() {final game = recruitWorkerParityAllTiersGame(); final list = suggestRecruitWorkerOrders(recruitWorkerTestViewFor(game,'p1'),game,recruitWorkerTestTopology,const Orders(),); expect(list.map((o) => o.targetTier).toList(),<WorkerTier>[WorkerTier.peasant,WorkerTier.apprentice,WorkerTier.journeyman,WorkerTier.master,]); for (final candidate in list) {expect(recruitWorkerTestEngineAccepts(game,const Orders(),'p1',candidate),isTrue,reason: 'engine accepts every emitted candidate (parity)',); }}

void osrwRunPeasantReservationExcludesApprenticeCandidate() {final game = recruitWorkerParityPeasantReservationGame(); final list = suggestRecruitWorkerOrders(recruitWorkerTestViewFor(game,'p1'),game,recruitWorkerTestTopology,recruitWorkerParityPeasantReservationOrders,); expect(list.any((o) => o.targetTier == WorkerTier.apprentice),isFalse,reason: 'peasant reservation ledger: pending apprentice already ' 'consumed the only peasant',); expect(list.any((o) => o.targetTier == WorkerTier.peasant),isTrue,reason: 'peasant recruit does not consume peasants',);}

void osrwRunEngineRoundTripParityPartialFixture() {final game = recruitWorkerParityPartialTechFixtureGame(); final list = suggestRecruitWorkerOrders(recruitWorkerTestViewFor(game,'p1'),game,recruitWorkerTestTopology,const Orders(),); expect(list.map((o) => o.targetTier).toSet(),{WorkerTier.peasant,WorkerTier.apprentice,}); for (final tier in recruitWorkerTestAllTiers) {final candidate = RecruitWorkerOrder(targetTier: tier); final inSuggestions = list.any((o) => o.targetTier == candidate.targetTier); final engineAccepts = recruitWorkerTestEngineAccepts(game,const Orders(),'p1',candidate,); expect(inSuggestions,engineAccepts,reason: '${tier.name}: suggestion inclusion ($inSuggestions) must ' 'match engine accept ($engineAccepts) — ' 'SPEC equivalence guarantee for incremental candidate ' 'validation',); }}

void osrwRunEmptyPlayerReturnsEmptyList() {final game = recruitWorkerParityEmptyPlayerGame(); final list = suggestRecruitWorkerOrders(recruitWorkerTestViewFor(game,'p1'),game,recruitWorkerTestTopology,const Orders(),); expect(list,isEmpty); for (final tier in recruitWorkerTestAllTiers) {expect(recruitWorkerTestEngineAccepts(game,const Orders(),'p1',RecruitWorkerOrder(targetTier: tier),),isFalse,reason: '${tier.name} candidate must be engine-rejected ' '(empty player has nothing to spend)',); }}

List<RunnableScenario>
orderSuggestionRecruitWorkerInclusionScenarios() => [
  rs('returns peasant and apprentice when fabric, treasury, paper, and apprentice tech support both rows', osrwRunReturnsPeasantAndApprenticeWhenSupported, '#2692 S7'),
  rs('omits trained tiers when their required techs are locked', osrwRunOmitsTrainedTiersWhenTechsLocked, '#2692 S7'),
  rs('omits peasant recruit when fabric is insufficient', osrwRunOmitsPeasantWhenFabricInsufficient, '#2692 S7'),
  rs('omits apprentice recruit when treasury is below 200 ducats', osrwRunOmitsApprenticeWhenTreasuryBelow200, '#2692 S7'),
  rs('omits apprentice recruit when peasant pool is empty', osrwRunOmitsApprenticeWhenPeasantPoolEmpty, '#2692 S7'),
];

List<RunnableScenario> orderSuggestionRecruitWorkerParityScenarios() => [
  rs('returns all four tiers when all techs unlocked and resources support every cost row', osrwRunReturnsAllFourTiersWhenFullyUnlocked, '#2692 S7'),
  rs('peasant reservation: pending apprentice recruit drains the only peasant so a candidate apprentice is excluded but candidate peasant remains', osrwRunPeasantReservationExcludesApprenticeCandidate, '#2692 S7'),
  rs('engine round-trip parity: accept/reject decision matches addRecruitWorkerOrderWithContext for every WorkerTier in a partial tech / peasant / treasury fixture', osrwRunEngineRoundTripParityPartialFixture, '#2692 S7'),
  rs('empty stockpile + zero treasury + zero peasants -> empty list', osrwRunEmptyPlayerReturnsEmptyList, '#2692 S7'),
];
