import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_console_parser_helpers.dart';
import 'debug_console_parsed_invocation.dart';

typedef DebugConsoleSessionDispatch = ({
  List<SessionCommandEvent> events,
  String message,
});

DebugConsoleSessionDispatch? dispatchDebugConsoleSessionEvents(
  DebugConsoleParsedInvocation invocation, {
  required String humanPlayerId,
}) {
  return switch (invocation) {
    DebugConsoleSpawnCivilianAtCapital(:final unitType, :final count) => (
      events: [
        SpawnDebugCivilianAtCapitalEvent(
          humanPlayerId: humanPlayerId,
          unitType: unitType,
          count: count,
        ),
      ],
      message: 'Queued debug spawn: ${count}x $unitType at capital.',
    ),
    DebugConsoleSpawnRegimentAtCapital(:final regimentTypeId, :final count) => (
      events: [
        SpawnDebugRegimentAtCapitalEvent(
          humanPlayerId: humanPlayerId,
          regimentTypeId: regimentTypeId,
          count: count,
        ),
      ],
      message:
          'Queued debug regiment spawn: ${count}x $regimentTypeId at capital.',
    ),
    DebugConsoleSpawnShipAtCapitalHomeFleet(:final shipTypeId, :final count) => (
      events: [
        SpawnDebugShipAtCapitalHomeFleetEvent(
          humanPlayerId: humanPlayerId,
          shipTypeId: shipTypeId,
          count: count,
        ),
      ],
      message:
          'Queued debug ship spawn: ${count}x $shipTypeId at capital home fleet.',
    ),
    DebugConsoleTreasuryCredit(
      :final requestedAmount,
      :final creditedAmount,
    ) =>
      (
        events: [
          CreditDebugTreasuryEvent(
            humanPlayerId: humanPlayerId,
            requestedAmount: requestedAmount,
            creditedAmount: creditedAmount,
          ),
        ],
        message: creditExecutorMessage(
          what: 'treasury credit',
          requestedAmount: requestedAmount,
          creditedAmount: creditedAmount,
        ),
      ),
    DebugConsoleWorkerPoolCredit(
      :final workerTierId,
      :final requestedAmount,
      :final creditedAmount,
    ) =>
      (
        events: [
          CreditDebugWorkerPoolEvent(
            humanPlayerId: humanPlayerId,
            workerTierId: workerTierId,
            requestedAmount: requestedAmount,
            creditedAmount: creditedAmount,
          ),
        ],
        message: creditExecutorMessage(
          what: 'worker credit',
          requestedAmount: requestedAmount,
          creditedAmount: creditedAmount,
          qualifier: workerTierId,
        ),
      ),
    DebugConsoleStockpileCredit(
      :final commodityId,
      :final requestedAmount,
      :final creditedAmount,
    ) =>
      (
        events: [
          CreditDebugStockpileCommodityEvent(
            humanPlayerId: humanPlayerId,
            commodityId: commodityId,
            requestedAmount: requestedAmount,
            creditedAmount: creditedAmount,
          ),
        ],
        message: creditExecutorMessage(
          what: 'stockpile credit for $commodityId',
          requestedAmount: requestedAmount,
          creditedAmount: creditedAmount,
        ),
      ),
    DebugConsoleFlipProvince(
      :final fullProvinceId,
      :final regionId,
      :final provinceDisplayName,
    ) =>
      (
        events: [
          FlipDebugProvinceOwnershipEvent(
            humanPlayerId: humanPlayerId,
            fullProvinceId: fullProvinceId,
            regionId: regionId,
            provinceDisplayName: provinceDisplayName,
          ),
        ],
        message: fullProvinceId != null
            ? 'Queued debug province flip by id: $fullProvinceId.'
            : 'Queued debug province flip: $regionId / $provinceDisplayName.',
      ),
    DebugConsoleRevealProvince(:final target, :final targetIsFullProvinceId) => (
      events: [
        RevealDebugProvinceEvent(
          humanPlayerId: humanPlayerId,
          target: target,
          targetIsFullProvinceId: targetIsFullProvinceId,
        ),
      ],
      message: targetIsFullProvinceId
          ? 'Queued debug province reveal by id: $target.'
          : 'Queued debug province reveal by name: $target.',
    ),
    DebugConsoleSetDiplomacy(:final factionA, :final factionB, :final action) =>
      (
        events: [
          SetDebugDiplomacyRelationEvent(
            humanPlayerId: humanPlayerId,
            factionA: factionA,
            factionB: factionB,
            action: action,
          ),
        ],
        message: factionA == null
            ? 'Queued debug diplomacy: ${action.keyword} with $factionB.'
            : 'Queued debug diplomacy: ${action.keyword} between '
                  '$factionA and $factionB.',
      ),
    _ => null,
  };
}

String creditExecutorMessage({
  required String what,
  required int requestedAmount,
  required int creditedAmount,
  String? qualifier,
}) {
  final label = qualifier == null ? what : '$what ($qualifier)';
  if (requestedAmount != creditedAmount) {
    return 'Queued debug $label: requested $requestedAmount, '
        'crediting $creditedAmount (clamped to $kDebugConsoleMaxTreasuryCreditAmount).';
  }
  return 'Queued debug $label: $creditedAmount.';
}
