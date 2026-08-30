import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Field-extraction cases for session command payload smoke tests.
List<(Object? actual, Object? expected)> sessionCommandPayloadCases() => [
      (
        RemovePendingWorkOrderRequestedEvent(playerId: 'p1', index: 2).index,
        2,
      ),
      (
        NavalSplitFleetRequestedEvent(
          humanPlayerId: 'p1',
          originalFleetId: 'f1',
          shipInstanceIdsToNewFleet: const ['ship_1'],
        ).originalFleetId,
        'f1',
      ),
      (
        NavalTransferShipsRequestedEvent(
          humanPlayerId: 'p1',
          sourceFleetId: 'f1',
          targetFleetId: 'f2',
          shipInstanceIdsToTransfer: const ['ship_1'],
        ).targetFleetId,
        'f2',
      ),
      (
        NavalMoveFleetRequestedEvent(
          humanPlayerId: 'p1',
          moveOrder: const NavalMoveOrder(
            fleetId: 'f1',
            destinationSeaZoneId: 'sz1',
          ),
        ).moveOrder.fleetId,
        'f1',
      ),
      (
        NavalMissionRequestedEvent(
          humanPlayerId: 'p1',
          missionOrder: NavalMissionOrder(
            fleetId: 'f1',
            mission: FleetMission.patrol.name,
          ),
        ).missionOrder.mission,
        FleetMission.patrol.name,
      ),
      (
        NavalMissionCancelRequestedEvent(
          humanPlayerId: 'p1',
          fleetId: 'f1',
        ).fleetId,
        'f1',
      ),
      (
        ArmyCombineRequestedEvent(
          humanPlayerId: 'p1',
          armyIds: const ['a1'],
        ).armyIds,
        ['a1'],
      ),
      (
        ArmySplitRequestedEvent(
          humanPlayerId: 'p1',
          sourceArmyId: 'a1',
          unitIdsToMove: const ['u1'],
        ).sourceArmyId,
        'a1',
      ),
      (
        ArmyMoveRequestedEvent(
          humanPlayerId: 'p1',
          moveOrder: const ArmyMoveOrder(
            armyId: 'a1',
            destinationProvinceId: 'r1|p1',
          ),
          declareWarTargetFactionId: 'B',
        ).declareWarTargetFactionId,
        'B',
      ),
      (
        const SpawnDebugRegimentAtCapitalEvent(
          humanPlayerId: 'p1',
          regimentTypeId: 'line_infantry',
        ).regimentTypeId,
        'line_infantry',
      ),
      (
        const SpawnDebugShipAtCapitalHomeFleetEvent(
          humanPlayerId: 'p1',
          shipTypeId: 'carrack',
        ).shipTypeId,
        'carrack',
      ),
      (
        const CreditDebugWorkerPoolEvent(
          humanPlayerId: 'p1',
          workerTierId: 'peasants',
          requestedAmount: 5,
          creditedAmount: 5,
        ).workerTierId,
        'peasants',
      ),
      (
        const CreditDebugStockpileCommodityEvent(
          humanPlayerId: 'p1',
          commodityId: 'grain',
          requestedAmount: 5,
          creditedAmount: 5,
        ).commodityId,
        'grain',
      ),
      (
        const RevealDebugProvinceEvent(
          humanPlayerId: 'p1',
          target: 'r1|p1',
          targetIsFullProvinceId: true,
        ).targetIsFullProvinceId,
        isTrue,
      ),
      (const SetObserveModeOffEvent(), isA<SessionCommandEvent>()),
      (const SetObserveModeGlobalEvent(), isA<SessionCommandEvent>()),
      (
        const SetObserveModePlayerEvent(targetPlayerId: 'p2').targetPlayerId,
        'p2',
      ),
      (
        AppendDiplomaticOrderRequestedEvent(
          playerId: 'p1',
          order: const DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'B',
          ),
        ).order.targetFactionId,
        'B',
      ),
      (
        RemoveDiplomaticOrderRequestedEvent(
          playerId: 'p1',
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'B',
        ).type,
        DiplomaticOrderType.alliance,
      ),
      (
        const NegotiationMoodUpdateEvent(
          leaderId: 'v',
          currentMood: 'neutral',
          offerQualityDelta: 0.2,
          stallCounter: 1,
          seed: 7,
        ).durationMs,
        1200,
      ),
    ];

void expectSessionCommandPayloadCases() {
  for (final (actual, expected) in sessionCommandPayloadCases()) {
    expect(actual, expected);
  }
}
