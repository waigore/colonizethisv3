// Table-driven multi-slot research suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_research_multi_slot_fixtures.dart';
// dart format off

void osrmsRunFillsEveryEmptySlotWithDistinctResearchableTech() {const player = Player(id: researchDiversifyPlayerId, displayName: 'GP', isHuman: false, treasury: 1000, researchSlots: 3); final game = researchDiversifyGameFor(player); final view = buildPlayerView(game, researchDiversifyTopology, researchDiversifyPlayerId); final suggestions = suggestResearchOrders(view, game, researchDiversifyTopology, const Orders()); expect(suggestions.length, greaterThanOrEqualTo(2), reason: 'multiple era-1 techs are researchable from an empty state'); expect(suggestions.length, lessThanOrEqualTo(3), reason: 'never exceeds the player research slot count'); final slotIndices = suggestions.map((o) => o.slotIndex).toSet(); expect(slotIndices.length, suggestions.length, reason: 'each suggestion targets a distinct slot'); for (final slot in slotIndices) {expect(slot, inInclusiveRange(0, 2));} final techIds = suggestions.map((o) => o.techId).toSet(); expect(techIds.length, suggestions.length, reason: 'each suggestion targets a distinct tech');}

void osrmsRunReEmitsInProgressResearch() {final researchable = researchableTechIds(const <String,bool>{}).toList()..sort(); expect(researchable,isNotEmpty); final inProgressTechId = researchable.first; final player = Player(id: researchDiversifyPlayerId,displayName: 'GP',isHuman: false,treasury: 1000,researchSlots: 3,researchProgressByTechId: {inProgressTechId: 25},); final game = researchDiversifyGameFor(player); final view = buildPlayerView(game,researchDiversifyTopology,researchDiversifyPlayerId,); final suggestions = suggestResearchOrders(view,game,researchDiversifyTopology,const Orders(),); expect(suggestions.map((o) => o.techId),contains(inProgressTechId),reason: 'in-progress techs must be re-emitted to keep their progress',);}

void osrmsRunReturnsNoSuggestionsWhenZeroResearchSlots() {const player = Player(id: researchDiversifyPlayerId,displayName: 'GP',isHuman: false,treasury: 1000,researchSlots: 0,); final game = researchDiversifyGameFor(player); final view = buildPlayerView(game,researchDiversifyTopology,researchDiversifyPlayerId,); final suggestions = suggestResearchOrders(view,game,researchDiversifyTopology,const Orders(),); expect(suggestions,isEmpty);}

void osrmsRunDoesNotReSuggestTechAlreadyAssignedByPendingOrder() {final researchable = researchableTechIds(const <String, bool>{}).toList()..sort(); expect(researchable.length, greaterThanOrEqualTo(2)); final pendingTechId = researchable.first; const player = Player(id: researchDiversifyPlayerId, displayName: 'GP', isHuman: false, treasury: 1000, researchSlots: 3); final game = researchDiversifyGameFor(player); final view = buildPlayerView(game, researchDiversifyTopology, researchDiversifyPlayerId); final pending = Orders(researchOrdersByPlayerId: {researchDiversifyPlayerId: [ResearchOrder(slotIndex: 0, techId: pendingTechId, funding: ResearchFundingLevel.medium)]}); final suggestions = suggestResearchOrders(view, game, researchDiversifyTopology, pending); expect(suggestions.map((o) => o.techId), isNot(contains(pendingTechId)), reason: 'a tech already taken by a pending order is not re-suggested'); expect(suggestions.map((o) => o.slotIndex), isNot(contains(0)), reason: 'slot 0 is already taken by the pending order');}

List<RunnableScenario> orderSuggestionResearchMultiSlotScenarios() => [
  rs('fills every empty slot with a distinct researchable tech', osrmsRunFillsEveryEmptySlotWithDistinctResearchableTech, '#3472'),
  rs('re-emits in-progress research so the resolver preserves progress', osrmsRunReEmitsInProgressResearch, '#3472'),
  rs('returns no suggestions when there are zero research slots', osrmsRunReturnsNoSuggestionsWhenZeroResearchSlots, '#3472'),
  rs('does not re-suggest a tech already assigned by a pending order', osrmsRunDoesNotReSuggestTechAlreadyAssignedByPendingOrder, '#3472'),
];
