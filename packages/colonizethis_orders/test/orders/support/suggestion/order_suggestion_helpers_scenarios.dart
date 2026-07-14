// Table-driven order suggestion helper scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_helpers.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_helpers_fixtures.dart';
// dart format off

void oshRunDropsMoveWhenRelationAbsent() {final game = orderSuggestionHelpersGameWithMinorProvince(diplomacyRelations: const [],); const orders = [ArmyMoveOrder(armyId: 'a1',destinationProvinceId: '$orderSuggestionHelpersOw|P_minor',),]; final out = filterArmyMoveOrdersByDiplomacy(game,orderSuggestionHelpersGpId,orders,); expect(out,isEmpty);}

void oshRunKeepsMoveWhenAtWar() {final game = orderSuggestionHelpersGameWithMinorProvince(diplomacyRelations: [DiplomacyRelation(factionId1: orderSuggestionHelpersGpId,factionId2: orderSuggestionHelpersMinorId,state: RelationState.atWar,),],); const orders = [ArmyMoveOrder(armyId: 'a1',destinationProvinceId: '$orderSuggestionHelpersOw|P_minor',),]; final out = filterArmyMoveOrdersByDiplomacy(game,orderSuggestionHelpersGpId,orders,); expect(out,orders);}

void oshRunDropsMoveWhenAtPeace() {final game = orderSuggestionHelpersGameWithMinorProvince(diplomacyRelations: [DiplomacyRelation(factionId1: orderSuggestionHelpersGpId,factionId2: orderSuggestionHelpersMinorId,state: RelationState.atPeace,),],); const orders = [ArmyMoveOrder(armyId: 'a1',destinationProvinceId: '$orderSuggestionHelpersOw|P_minor',),]; final out = filterArmyMoveOrdersByDiplomacy(game,orderSuggestionHelpersGpId,orders,); expect(out,isEmpty);}

void oshRunKeepsReorderWithinOwnProvinces() {final game = orderSuggestionHelpersGameWithMinorProvince(diplomacyRelations: const [],); const orders = [ArmyMoveOrder(armyId: 'a1',destinationProvinceId: '$orderSuggestionHelpersOw|P_gp',),]; final out = filterArmyMoveOrdersByDiplomacy(game,orderSuggestionHelpersGpId,orders,); expect(out,orders);}

void oshRunKeepsMoveWhenDraftDeclaresWar() {final game = orderSuggestionHelpersGameWithMinorProvince(diplomacyRelations: [DiplomacyRelation(factionId1: orderSuggestionHelpersGpId,factionId2: orderSuggestionHelpersMinorId,state: RelationState.atPeace,),],); const armyOrders = [ArmyMoveOrder(armyId: 'a1',destinationProvinceId: '$orderSuggestionHelpersOw|P_minor',),]; final draftOrders = Orders(diplomaticOrdersByPlayerId: {orderSuggestionHelpersGpId: [DiplomaticOrder(type: DiplomaticOrderType.declareWar,targetFactionId: orderSuggestionHelpersMinorId,),],},); final out = filterArmyMoveOrdersByDiplomacy(game,orderSuggestionHelpersGpId,armyOrders,draftOrders: draftOrders,); expect(out,armyOrders);}

/// Scenarios for filterArmyMoveOrdersByDiplomacy.
List<RunnableScenario> filterArmyMoveOrdersByDiplomacyScenarios() => [
  rs('drops move into minor-owned province when relation row is absent', oshRunDropsMoveWhenRelationAbsent, '#2394'),
  rs('keeps move into minor province when at war (relation row present)', oshRunKeepsMoveWhenAtWar, '#2394'),
  rs('drops move into minor province when explicitly at peace', oshRunDropsMoveWhenAtPeace, '#2394'),
  rs('keeps reordering-only move within own provinces', oshRunKeepsReorderWithinOwnProvinces, '#2394'),
  rs('keeps move into minor at peace when draft orders declare war', oshRunKeepsMoveWhenDraftDeclaresWar, '#2394'),
];
