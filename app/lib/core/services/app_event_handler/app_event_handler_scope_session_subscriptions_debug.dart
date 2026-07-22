import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';

import '../debug/app_event_handler_debug_flip_province.dart'
    show applyDebugFlipProvinceOwnership;
import '../debug/app_event_handler_debug_reveal_province.dart'
    show applyDebugRevealProvince;
import '../debug/app_event_handler_debug_set_diplomacy.dart'
    show applyDebugSetDiplomacyRelation;
import '../debug/app_event_handler_debug_spawn_civilian.dart'
    show applyDebugCivilianSpawnAtCapital;
import '../debug/app_event_handler_debug_spawn_regiment.dart'
    show applyDebugRegimentSpawnAtCapital;
import '../debug/app_event_handler_debug_spawn_ship.dart'
    show applyDebugShipSpawnAtCapitalHomeFleet;
import '../debug/app_event_handler_debug_stockpile.dart'
    show applyDebugStockpileCredit;
import '../debug/app_event_handler_debug_treasury.dart'
    show applyDebugTreasuryCredit;
import '../debug/app_event_handler_debug_worker_pool.dart'
    show applyDebugWorkerPoolCredit;
import 'app_event_handler_scope_session_helpers.dart';

mixin AppEventHandlerScopeSessionDebugListeners
    on AppEventHandlerScopeSessionHelpers {
  List<StreamSubscription<dynamic>> debugSessionListeners(AppEventBus bus) {
    return [
      bus.on<SpawnDebugCivilianAtCapitalEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'SpawnDebugCivilianAtCapitalEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugCivilianSpawnAtCapital(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<SpawnDebugRegimentAtCapitalEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'SpawnDebugRegimentAtCapitalEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugRegimentSpawnAtCapital(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<SpawnDebugShipAtCapitalHomeFleetEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'SpawnDebugShipAtCapitalHomeFleetEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugShipSpawnAtCapitalHomeFleet(
                currentGame: current,
                event: e,
              ),
            );
          },
        );
      }),
      bus.on<CreditDebugTreasuryEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('CreditDebugTreasuryEvent', () {
          final current = ref.read(currentGameProvider);
          applyDebugCommand(
            applyDebugTreasuryCredit(currentGame: current, event: e),
          );
        });
      }),
      bus.on<CreditDebugWorkerPoolEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('CreditDebugWorkerPoolEvent', () {
          final current = ref.read(currentGameProvider);
          applyDebugCommand(
            applyDebugWorkerPoolCredit(currentGame: current, event: e),
          );
        });
      }),
      bus.on<CreditDebugStockpileCommodityEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'CreditDebugStockpileCommodityEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugStockpileCredit(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<FlipDebugProvinceOwnershipEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'FlipDebugProvinceOwnershipEvent',
          () {
            final current = ref.read(currentGameProvider);
            final mapData = current == null
                ? null
                : ref.read(gameServiceProvider).getMapData(current.id);
            final result = applyDebugFlipProvinceOwnership(
              currentGame: current,
              event: e,
              combinedTopology:
                  mapData?.combinedTopology ?? const MapTopology(),
              topologyByRegion: mapData?.topologyByRegion,
            );
            applyDebugCommand(result);
          },
        );
      }),
      bus.on<RevealDebugProvinceEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('RevealDebugProvinceEvent', () {
          final current = ref.read(currentGameProvider);
          final mapData = current == null
              ? null
              : ref.read(gameServiceProvider).getMapData(current.id);
          final result = applyDebugRevealProvince(
            currentGame: current,
            event: e,
            combinedTopology: mapData?.combinedTopology ?? const MapTopology(),
            topologyByRegion: mapData?.topologyByRegion,
          );
          applyDebugCommand(result);
        });
      }),
      bus.on<SetDebugDiplomacyRelationEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'SetDebugDiplomacyRelationEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugSetDiplomacyRelation(currentGame: current, event: e),
            );
          },
        );
      }),
    ];
  }
}
