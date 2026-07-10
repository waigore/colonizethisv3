// Table-driven feedstock-priority build_improvement suggestion scenarios (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        feedstockBootstrapBuildImprovementCastIronWaived,
        feedstockExtractionResourceIdsForPlayer;
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_work_feedstock_priority_fixtures.dart';
// dart format off

void oswfpRunSupplierGateActiveIronNotLexFirstGrain() {final game = feedstockPriorityGame(); expect(feedstockExtractionResourceIdsForPlayer(game,feedstockPrioritySupplierId),contains('iron'),); final improvements = feedstockPriorityBuildImprovementSuggestions(game); expect(improvements,isNotEmpty); expect(improvements.map((o) => o.targetTileKey),contains(feedstockPrioritySupplierIronTile),reason: 'feedstock-priority ordering must surface the iron tile as a ' 'build_improvement suggestion',); expect(improvements.single.targetTileKey,feedstockPrioritySupplierIronTile);}

void oswfpRunSupplierGateInactivePeerAtQuotaLexGrain() {final game = feedstockPriorityGame(sellerOw: kObserverConquestMinOwProvincesPerGp,supplierCastIron: 10,); expect(feedstockExtractionResourceIdsForPlayer(game,feedstockPrioritySupplierId),isEmpty,); final improvements = feedstockPriorityBuildImprovementSuggestions(game); expect(improvements,isNotEmpty); expect(improvements.single.targetTileKey,feedstockPrioritySupplierGrainTile);}

void oswfpRunSupplierLumberOnlyCastIronWaiver() {final game = feedstockPriorityGame(); expect(feedstockBootstrapBuildImprovementCastIronWaived(game,feedstockPrioritySupplierId,feedstockPrioritySupplierIronTile,),isTrue,); final improvements = feedstockPriorityBuildImprovementSuggestions(game); expect(improvements.single.targetTileKey,feedstockPrioritySupplierIronTile);}

void oswfpRunSuggestionOrderingDeterministicRepeatedPasses() {final game = feedstockPriorityGame(); final first = feedstockPriorityBuildImprovementSuggestions(game,).map((o) => o.targetTileKey).toList(); final second = feedstockPriorityBuildImprovementSuggestions(game,).map((o) => o.targetTileKey).toList(); expect(first,equals(second)); expect(first.single,feedstockPrioritySupplierIronTile);}

void oswfpRunCoAvailSupplierHoldsTimberNotIronLeastHeldIron() {final game = feedstockCoAvailGame(supplierTimberHeld: 13,supplierIronHeld: 0,); expect(feedstockExtractionResourceIdsForPlayer(game,feedstockPrioritySupplierId),containsAll(<String>['timber','iron']),); final improvements = feedstockPriorityBuildImprovementSuggestions(game); expect(improvements,isNotEmpty); expect(improvements.single.targetTileKey,feedstockCoAvailIronTile,reason: 'co-availability ordering must surface the missing co-feedstock ' '(iron) ahead of the already-held timber tile',);}

void oswfpRunCoAvailEqualFeedstockLexTimberNegativeControl() {final game = feedstockCoAvailGame(supplierTimberHeld: 0,supplierIronHeld: 0); final improvements = feedstockPriorityBuildImprovementSuggestions(game); expect(improvements,isNotEmpty); expect(improvements.single.targetTileKey,feedstockCoAvailTimberTile);}

void oswfpRunCoAvailOrderingDeterministicRepeatedPasses() {final game = feedstockCoAvailGame(supplierTimberHeld: 13,supplierIronHeld: 0,); final first = feedstockPriorityBuildImprovementSuggestions(game,).map((o) => o.targetTileKey).toList(); final second = feedstockPriorityBuildImprovementSuggestions(game,).map((o) => o.targetTileKey).toList(); expect(first,equals(second)); expect(first.single,feedstockCoAvailIronTile);}

/// Feedstock-extraction priority scenarios (Refs #2847 H8-extraction).
List<RunnableScenario>
orderSuggestionWorkFeedstockPriorityExtractionScenarios() => [
  rs('supplier gate active: the emitted build_improvement suggestion targets the unimproved iron feedstock tile, not the lex-first grain tile', oswfpRunSupplierGateActiveIronNotLexFirstGrain, '#2847'),
  rs('supplier gate inactive (peer at quota): ordinary lexicographic ordering emits the grain tile (negative control)', oswfpRunSupplierGateInactivePeerAtQuotaLexGrain, '#2847'),
  rs('supplier with lumber only: feedstock build_improvement is accepted under castIron waiver', oswfpRunSupplierLumberOnlyCastIronWaiver, '#2847'),
  rs('suggestion ordering is deterministic across repeated passes', oswfpRunSuggestionOrderingDeterministicRepeatedPasses, '#2847'),
];

/// Feedstock co-availability ordering scenarios (Refs #2847 H8-extraction).
List<RunnableScenario> orderSuggestionWorkFeedstockCoAvailScenarios() => [
  rs('supplier holds timber but no iron: the emitted build_improvement suggestion targets the least-held iron tile, not the lex-first timber tile', oswfpRunCoAvailSupplierHoldsTimberNotIronLeastHeldIron, '#2847'),
  rs('supplier holds equal feedstock (zero of each): lexicographic tie-break emits the timber tile (negative control)', oswfpRunCoAvailEqualFeedstockLexTimberNegativeControl, '#2847'),
  rs('co-availability ordering is deterministic across repeated passes', oswfpRunCoAvailOrderingDeterministicRepeatedPasses, '#2847'),
];
