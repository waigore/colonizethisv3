import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

class GameEventBridge {
  GameEventBridge({required GameEventBus logicBus, required AppEventBus appBus})
    : _logicBus = logicBus,
      _appBus = appBus;

  final GameEventBus _logicBus;
  final AppEventBus _appBus;
  void Function()? _unsubscribe;

  GameEventBus get logicBus => _logicBus;

  void start() {
    if (_unsubscribe != null) return;
    _unsubscribe = _logicBus.subscribe<GameEvent>(_forward);
  }

  void stop() {
    _unsubscribe?.call();
    _unsubscribe = null;
  }

  void dispose() {
    stop();
  }

  void _forward(GameEvent event) {
    switch (event) {
      case CombatResultEvent():
        _appBus.emit(
          AppCombatResultEvent(
            provinceId: event.provinceId,
            attackerId: event.attackerId,
            defenderId: event.defenderId,
            winnerId: event.winnerId,
            turnNumber: event.turnNumber,
            casualties: event.casualties,
          ),
        );
      case NavalCombatResultEvent():
        _appBus.emit(
          AppNavalCombatResultEvent(
            seaZoneId: event.seaZoneId,
            side1OwnerId: event.side1OwnerId,
            side2OwnerId: event.side2OwnerId,
            outcomeName: event.outcomeName,
            turnNumber: event.turnNumber,
            winnerOwnerId: event.winnerOwnerId,
            side1Retreated: event.side1Retreated,
            side2Retreated: event.side2Retreated,
          ),
        );
      case ProvinceCapturedEvent():
        _appBus.emit(
          AppProvinceCapturedEvent(
            provinceId: event.provinceId,
            previousOwnerId: event.previousOwnerId,
            newOwnerId: event.newOwnerId,
            turnNumber: event.turnNumber,
          ),
        );
      case DiplomacyChangeEvent():
        _appBus.emit(
          AppDiplomacyChangeEvent(
            actorId: event.actorId,
            targetId: event.targetId,
            changeType: event.changeType,
            turnNumber: event.turnNumber,
          ),
        );
      case ResearchCompleteEvent():
        _appBus.emit(
          AppResearchCompleteEvent(
            playerId: event.playerId,
            techId: event.techId,
            turnNumber: event.turnNumber,
          ),
        );
      case VictorySetEvent():
        _appBus.emit(
          AppVictorySetEvent(
            winnerPlayerId: event.winnerPlayerId,
            victoryType: event.victoryType,
            turnNumber: event.turnNumber,
          ),
        );
      case OrderRejectedEvent():
        _appBus.emit(
          AppOrderRejectedEvent(
            playerId: event.playerId,
            orderSummary: event.orderSummary,
            reasonCode: event.reasonCode,
          ),
        );
      case WorkOrderCompletedEvent():
        _appBus.emit(
          AppWorkOrderCompletedEvent(
            playerId: event.playerId,
            unitId: event.unitId,
            workTarget: event.workTarget,
            targetTileKey: event.targetTileKey,
            provinceId: event.provinceId,
            turnNumber: event.turnNumber,
          ),
        );
      case PlayerProvinceDiscoveredEvent():
        _appBus.emit(
          AppPlayerProvinceDiscoveredEvent(
            playerId: event.playerId,
            provinceId: event.provinceId,
            turnNumber: event.turnNumber,
          ),
        );
      case PlayerSeaZoneDiscoveredEvent():
        _appBus.emit(
          AppPlayerSeaZoneDiscoveredEvent(
            playerId: event.playerId,
            seaZoneId: event.seaZoneId,
            turnNumber: event.turnNumber,
          ),
        );
      case OvertureAdvancedEvent():
        _appBus.emit(
          AppOvertureAdvancedEvent(
            offererGpId: event.offererGpId,
            targetFactionId: event.targetFactionId,
            newStage: event.newStage,
            turnNumber: event.turnNumber,
          ),
        );
      case SpyCaughtEvent():
        _appBus.emit(
          AppSpyCaughtEvent(
            unitId: event.unitId,
            spyOwnerId: event.spyOwnerId,
            territoryOwnerId: event.territoryOwnerId,
            provinceId: event.provinceId,
            turnNumber: event.turnNumber,
          ),
        );
      case SpyDefectedEvent():
        _appBus.emit(
          AppSpyDefectedEvent(
            unitId: event.unitId,
            previousOwnerId: event.previousOwnerId,
            newOwnerId: event.newOwnerId,
            provinceId: event.provinceId,
            turnNumber: event.turnNumber,
          ),
        );
    }
  }
}
