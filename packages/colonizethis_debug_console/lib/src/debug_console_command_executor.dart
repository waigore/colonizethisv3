import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_console_command_parser.dart';
import 'debug_console_parsed_invocation.dart';

class DebugConsoleExecutionContext {
  const DebugConsoleExecutionContext({this.selectedTileKey});

  final String? selectedTileKey;
}

class DebugConsoleCommandExecutor {
  const DebugConsoleCommandExecutor({
    DebugConsoleCommandParser parser = const DebugConsoleCommandParser(),
  }) : _parser = parser;

  final DebugConsoleCommandParser _parser;

  DebugConsoleExecutionResult executeRaw({
    required String rawInput,
    required String humanPlayerId,
    DebugConsoleExecutionContext? context,
  }) {
    final parsed = _parser.parse(rawInput);
    if (parsed.isError) {
      return DebugConsoleExecutionResult.error(
        parsed.message ?? 'Invalid command.',
      );
    }
    final invocation = parsed.invocation;
    if (invocation == null) {
      return const DebugConsoleExecutionResult.error('Invalid command.');
    }
    return _executeInvocation(
      invocation,
      humanPlayerId: humanPlayerId,
      context: context,
    );
  }

  DebugConsoleExecutionResult _executeInvocation(
    DebugConsoleParsedInvocation invocation, {
    required String humanPlayerId,
    DebugConsoleExecutionContext? context,
  }) {
    return switch (invocation) {
      DebugConsoleSpawnCivilianAtCapital(:final unitType, :final count) =>
        DebugConsoleExecutionResult.success(
          events: [
            SpawnDebugCivilianAtCapitalEvent(
              humanPlayerId: humanPlayerId,
              unitType: unitType,
              count: count,
            ),
          ],
          message: 'Queued debug spawn: ${count}x $unitType at capital.',
        ),
      DebugConsoleSpawnRegimentAtCapital(:final regimentTypeId, :final count) =>
        DebugConsoleExecutionResult.success(
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
      DebugConsoleSpawnShipAtCapitalHomeFleet(
        :final shipTypeId,
        :final count,
      ) =>
        DebugConsoleExecutionResult.success(
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
        DebugConsoleExecutionResult.success(
          events: [
            CreditDebugTreasuryEvent(
              humanPlayerId: humanPlayerId,
              requestedAmount: requestedAmount,
              creditedAmount: creditedAmount,
            ),
          ],
          message: _treasuryCreditExecutorMessage(
            requestedAmount: requestedAmount,
            creditedAmount: creditedAmount,
          ),
        ),
      DebugConsoleStockpileCredit(
        :final commodityId,
        :final requestedAmount,
        :final creditedAmount,
      ) =>
        DebugConsoleExecutionResult.success(
          events: [
            CreditDebugStockpileCommodityEvent(
              humanPlayerId: humanPlayerId,
              commodityId: commodityId,
              requestedAmount: requestedAmount,
              creditedAmount: creditedAmount,
            ),
          ],
          message: _stockpileCreditExecutorMessage(
            commodityId: commodityId,
            requestedAmount: requestedAmount,
            creditedAmount: creditedAmount,
          ),
        ),
      DebugConsoleFlipProvince(
        :final fullProvinceId,
        :final regionId,
        :final provinceDisplayName,
      ) =>
        DebugConsoleExecutionResult.success(
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
      DebugConsoleRevealProvince(
        :final target,
        :final targetIsFullProvinceId,
      ) =>
        DebugConsoleExecutionResult.success(
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
      DebugConsoleGetTileBasicInfo() => _executeGetTileBasicInfo(context),
    };
  }
}

DebugConsoleExecutionResult _executeGetTileBasicInfo(
  DebugConsoleExecutionContext? context,
) {
  final selectedTileKey = context?.selectedTileKey?.trim();
  if (selectedTileKey == null || selectedTileKey.isEmpty) {
    return const DebugConsoleExecutionResult.error('No tile is selected.');
  }
  // Keep parsing local to this package to avoid app-layer coupling.
  final provinceId = _provinceIdFromTileKey(selectedTileKey);
  if (provinceId == null) {
    return const DebugConsoleExecutionResult.error(
      'Selected tile key is invalid.',
    );
  }
  return DebugConsoleExecutionResult.success(
    events: const [],
    message: 'tile_id: $selectedTileKey\nprovince_id: $provinceId',
  );
}

String? _provinceIdFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) {
    return null;
  }
  return '${parts[0]}|${parts[1]}';
}

String _treasuryCreditExecutorMessage({
  required int requestedAmount,
  required int creditedAmount,
}) {
  if (requestedAmount != creditedAmount) {
    return 'Queued debug treasury credit: requested $requestedAmount, '
        'crediting $creditedAmount (clamped to $kDebugConsoleMaxTreasuryCreditAmount).';
  }
  return 'Queued debug treasury credit: $creditedAmount.';
}

String _stockpileCreditExecutorMessage({
  required String commodityId,
  required int requestedAmount,
  required int creditedAmount,
}) {
  if (requestedAmount != creditedAmount) {
    return 'Queued debug stockpile credit for $commodityId: requested '
        '$requestedAmount, crediting $creditedAmount (clamped to '
        '$kDebugConsoleMaxTreasuryCreditAmount).';
  }
  return 'Queued debug stockpile credit for $commodityId: $creditedAmount.';
}

class DebugConsoleExecutionResult {
  const DebugConsoleExecutionResult.success({
    required this.events,
    required this.message,
  }) : isError = false;

  const DebugConsoleExecutionResult.error(this.message)
    : events = const [],
      isError = true;

  final List<SessionCommandEvent> events;
  final String message;
  final bool isError;
}
