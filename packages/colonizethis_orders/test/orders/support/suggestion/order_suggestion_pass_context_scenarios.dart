// Table-driven order suggestion pass context scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_army_move_destinations.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_pass_context.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../scenario_runner.dart';
import 'order_suggestion_pass_context_fixtures.dart';
// dart format off

void ospcRunIndexSkipsEmptyTargets() {final indexed = indexExistingTargetsByEntityId(const [NavalMoveOrder(fleetId: 'f1',destinationSeaZoneId: 'seaA'),NavalMoveOrder(fleetId: 'f1',destinationSeaZoneId: ''),],(o) => o.fleetId,(o) => o.destinationSeaZoneId ?? '',skipEmptyTargets: true,); expect(indexed['f1'],{'seaA'});}

void ospcRunEmitCollectsInOrder() {final into = <NavalMoveOrder>[]; emitAcceptedCandidates<NavalMoveOrder>(candidates: const [NavalMoveOrder(fleetId: 'f1',destinationSeaZoneId: 'seaB'),NavalMoveOrder(fleetId: 'f1',destinationSeaZoneId: 'seaA'),NavalMoveOrder(fleetId: 'f1',destinationSeaZoneId: 'seaC'),],accept: (o) => o.destinationSeaZoneId != 'seaC',into: into,); expect(into.map((o) => o.destinationSeaZoneId).toList(),['seaB','seaA'],reason: 'preserves candidate order and performs no sorting',);}

void ospcRunEmitSkipsAlreadyTargeted() {final into = <NavalMoveOrder>[]; emitAcceptedCandidates<NavalMoveOrder>(candidates: const [NavalMoveOrder(fleetId: 'f1',destinationSeaZoneId: 'seaA'),NavalMoveOrder(fleetId: 'f1',destinationSeaZoneId: 'seaB'),NavalMoveOrder(fleetId: 'f2',destinationSeaZoneId: 'seaA'),],accept: (_) => true,into: into,existingByEntity: {'f1': {'seaA'},},entityId: (o) => o.fleetId,dedupKey: (o) => o.destinationSeaZoneId ?? '',); expect(into.map((o) => '${o.fleetId}:${o.destinationSeaZoneId}').toList(),['f1:seaB','f2:seaA',]);}

void ospcRunEmitProbesWithoutDedupArgs() {final into = <NavalMoveOrder>[]; emitAcceptedCandidates<NavalMoveOrder>(candidates: const [NavalMoveOrder(fleetId: 'f1',destinationSeaZoneId: 'seaA'),NavalMoveOrder(fleetId: 'f1',destinationSeaZoneId: 'seaA'),],accept: (_) => true,into: into,existingByEntity: {'f1': {'seaA'},},); expect(into.length,2);}

void ospcRunCappedProbeLoopRespectsCaps() {final accepted = <int>[]; final probes = List.generate(10,(i) => i); runCappedSuggestionProbeLoop<int>(candidates: probes,shouldSkip: (n) => n.isEven,probe: (n) => n % 3 == 1,onAccepted: accepted.add,maxAccepted: 2,maxProbes: 4,); expect(accepted,[1,7]);}

void ospcRunOwnedProvinceIdsFromView() {final view = buildPlayerView(orderSuggestionPassContextOwnedProvincesGame(),orderSuggestionPassContextTopology,orderSuggestionPassContextGp1Id,); expect(ownedProvinceIdsFromView(view,orderSuggestionPassContextGp1Id),{ProvinceId.full(kOldWorldRegionId,'p1'),});}

void ospcRunOwnedProvinceIdsForPlayerMatchesCache() {final game = orderSuggestionPassContextOwnedProvincesGame(); final fromHelper = ownedProvinceIdsForPlayer(game.worldState,orderSuggestionPassContextGp1Id); final fromCache = <String>{for (final p in ProvinceOwnerCache.of(game.worldState).provincesOwnedBy(orderSuggestionPassContextGp1Id)) ProvinceId.isPrefixed(p.id) ? p.id : ProvinceId.full(p.regionId,p.id),}; expect(fromHelper,fromCache); expect(fromHelper,{ProvinceId.full(kOldWorldRegionId,'p1'),});}

void ospcRunArmyMoveCacheMissEqualsOwnedForPlayer() {final game = orderSuggestionPassContextOwnedProvincesGame(); expect(armyMovePlayerOwnedProvinceIds(game: game,playerId: orderSuggestionPassContextGp1Id),ownedProvinceIdsForPlayer(game.worldState,orderSuggestionPassContextGp1Id),);}

void ospcRunOwnedHelpersEmptyWhenPlayerOwnsNone() {final game = orderSuggestionPassContextOwnedProvincesGame(); final view = buildPlayerView(game,orderSuggestionPassContextTopology,orderSuggestionPassContextGp1Id,); expect(ownedProvinceIdsForPlayer(game.worldState,'nobody'),isEmpty); expect(ownedProvinceIdsFromView(view,'nobody'),isEmpty); expect(armyMovePlayerOwnedProvinceIds(game: game,playerId: 'nobody'),isEmpty);}

void ospcRunWorkCacheDefaultOwnershipEqualsView() {Set<String>? captured; final cache = PerPlayerWorkTargetSelectionCache(strategies: {'x': (s) {captured = s.playerOwnedProvinceIds; return const <String>{};},},); final game = orderSuggestionPassContextOwnedProvincesGame(); final view = buildPlayerView(game,orderSuggestionPassContextTopology,orderSuggestionPassContextGp1Id,); cache.refresh(WorkTargetSelectionSnapshot(game: game,playerId: orderSuggestionPassContextGp1Id,playerView: view,topology: orderSuggestionPassContextTopology,currentOrders: const Orders(),tileMapByRegion: null,),); expect(captured,ownedProvinceIdsFromView(view,orderSuggestionPassContextGp1Id));}

/// Scenarios for indexExistingTargetsByEntityId.
List<RunnableScenario> indexExistingTargetsByEntityIdScenarios() => [
  rs('indexExistingTargetsByEntityId skips empty targets when requested', ospcRunIndexSkipsEmptyTargets, '#3500'),
];

/// Scenarios for emitAcceptedCandidates.
List<RunnableScenario> emitAcceptedCandidatesScenarios() => [
  rs('emitAcceptedCandidates collects accepted in iteration order', ospcRunEmitCollectsInOrder, '#3500'),
  rs('emitAcceptedCandidates skips candidates already targeted', ospcRunEmitSkipsAlreadyTargeted, '#3500'),
  rs('emitAcceptedCandidates probes every candidate without dedup args', ospcRunEmitProbesWithoutDedupArgs, '#3500'),
];

/// Scenarios for runCappedSuggestionProbeLoop.
List<RunnableScenario> runCappedSuggestionProbeLoopScenarios() => [
  rs('runCappedSuggestionProbeLoop respects acceptance and probe caps', ospcRunCappedProbeLoopRespectsCaps, '#3500'),
];

/// Scenarios for ownedProvinceIdsFromView.
List<RunnableScenario> ownedProvinceIdsFromViewScenarios() => [
  rs('ownedProvinceIdsFromView returns full province ids for owner', ospcRunOwnedProvinceIdsFromView, '#3500'),
];

/// Scenarios for ownedProvinceIdsForPlayer.
List<RunnableScenario> ownedProvinceIdsForPlayerScenarios() => [
  rs('ownedProvinceIdsForPlayer matches ProvinceOwnerCache projection', ospcRunOwnedProvinceIdsForPlayerMatchesCache, '#4258'),
  rs('armyMovePlayerOwnedProvinceIds cache-miss equals ownedProvinceIdsForPlayer', ospcRunArmyMoveCacheMissEqualsOwnedForPlayer, '#4587'),
  rs('owned helpers return empty when player owns no provinces', ospcRunOwnedHelpersEmptyWhenPlayerOwnsNone, '#4587'),
  rs('work-target cache default ownership equals ownedProvinceIdsFromView', ospcRunWorkCacheDefaultOwnershipEqualsView, '#4587'),
];
