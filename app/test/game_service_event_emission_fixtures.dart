// Shared fixtures for GameService event-emission tests (#4734 Slice J).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'app_test_hive_harness.dart';

class PendingOverturesGameService extends GameService {
  PendingOverturesGameService(super.box, super.adapter);

  @override
  TurnResolutionResult runTurnResolution(
    Game current, {
    Orders? orders,
    Orders? aiOrders,
    List<TurnTraceAiSection>? aiTraceSections,
    MapTopology? topology,
    Map<String, TileMapResult>? tileMapByRegion,
    void Function(GameEvent)? onGameEvent,
  }) {
    final humanId = current.players.firstWhere((p) => p.isHuman).id;
    eventBus?.emit(
      OvertureRequiredEvent(
        overtures: [
          OvertureOffer(
            offererGpId: 'gp2',
            targetFactionId: humanId,
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      ),
    );
    return TurnResolutionPendingOvertures(
      game: current,
      pendingOvertures: [
        OvertureOffer(
          offererGpId: 'gp2',
          targetFactionId: humanId,
          stage: OvertureStage.tradeConsulate,
        ),
      ],
    );
  }
}

Future<Box<dynamic>> openGameServiceEventEmissionHiveBox() {
  return openAppTestHiveBox(suiteId: 'game_service_event_emission');
}

void saveRequiredMapDataForGameServiceEventEmission(
  GameSaveAdapter adapter,
  Box<dynamic> box,
  String gameId,
) {
  final tileMap = TileMapResult(
    width: 1,
    height: 1,
    grid: [
      ['oldWorld|M1'],
    ],
  );
  final topo = const MapTopology(nodes: [], edges: []);
  adapter.saveMapData(
    box,
    gameId,
    tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
    topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
    combinedTopology: topo,
  );
}
