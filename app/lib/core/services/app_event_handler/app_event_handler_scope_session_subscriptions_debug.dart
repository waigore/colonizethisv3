part of 'app_event_handler_scope.dart';

extension _SessionDebugListeners on _AppEventHandlerScopeState {
  List<StreamSubscription<dynamic>> _debugSessionListeners(AppEventBus bus) {
    return [
      bus.on<SpawnDebugCivilianAtCapitalEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'SpawnDebugCivilianAtCapitalEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugCivilianSpawnAtCapital(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<SpawnDebugRegimentAtCapitalEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'SpawnDebugRegimentAtCapitalEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugRegimentSpawnAtCapital(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<SpawnDebugShipAtCapitalHomeFleetEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'SpawnDebugShipAtCapitalHomeFleetEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugShipSpawnAtCapitalHomeFleet(
                currentGame: current,
                event: e,
              ),
            );
          },
        );
      }),
      bus.on<CreditDebugTreasuryEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession('CreditDebugTreasuryEvent', () {
          final current = ref.read(currentGameProvider);
          _applyDebugCommand(
            applyDebugTreasuryCredit(currentGame: current, event: e),
          );
        });
      }),
      bus.on<CreditDebugWorkerPoolEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'CreditDebugWorkerPoolEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugWorkerPoolCredit(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<CreditDebugStockpileCommodityEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'CreditDebugStockpileCommodityEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugStockpileCredit(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<FlipDebugProvinceOwnershipEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
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
            _applyDebugCommand(result);
          },
        );
      }),
      bus.on<RevealDebugProvinceEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession('RevealDebugProvinceEvent', () {
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
          _applyDebugCommand(result);
        });
      }),
      bus.on<SetDebugDiplomacyRelationEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'SetDebugDiplomacyRelationEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugSetDiplomacyRelation(currentGame: current, event: e),
            );
          },
        );
      }),
    ];
  }
}
