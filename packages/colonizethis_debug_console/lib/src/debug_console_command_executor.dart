import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_console_command_parser.dart';
import 'debug_console_parsed_invocation.dart';

/// Narrow read-only projection for `/list_players` (see SPEC/ui/debug-console-panel).
class DebugConsolePlayerSnapshot {
  const DebugConsolePlayerSnapshot({
    required this.id,
    required this.displayName,
    required this.isHuman,
    this.capitalProvinceId,
  });

  final String id;
  final String displayName;
  final bool isHuman;
  final String? capitalProvinceId;
}

/// Submit-time snapshot for read-only debug commands (tile selection, player list).
class DebugConsoleReadOnlyContext {
  const DebugConsoleReadOnlyContext({this.selectedTileKey, this.players});

  final String? selectedTileKey;
  final List<DebugConsolePlayerSnapshot>? players;
}

class DebugConsoleCommandExecutor {
  const DebugConsoleCommandExecutor({
    DebugConsoleCommandParser parser = const DebugConsoleCommandParser(),
  }) : _parser = parser;

  final DebugConsoleCommandParser _parser;

  DebugConsoleExecutionResult executeRaw({
    required String rawInput,
    required String humanPlayerId,
    DebugConsoleReadOnlyContext? readOnlyContext,
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
      readOnlyContext: readOnlyContext,
    );
  }

  DebugConsoleExecutionResult _executeInvocation(
    DebugConsoleParsedInvocation invocation, {
    required String humanPlayerId,
    DebugConsoleReadOnlyContext? readOnlyContext,
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
      DebugConsoleWorkerPoolCredit(
        :final workerTierId,
        :final requestedAmount,
        :final creditedAmount,
      ) =>
        DebugConsoleExecutionResult.success(
          events: [
            CreditDebugWorkerPoolEvent(
              humanPlayerId: humanPlayerId,
              workerTierId: workerTierId,
              requestedAmount: requestedAmount,
              creditedAmount: creditedAmount,
            ),
          ],
          message: _workerPoolCreditExecutorMessage(
            workerTierId: workerTierId,
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
      DebugConsoleGetTileBasicInfo() => _executeGetTileBasicInfo(
        readOnlyContext,
      ),
      DebugConsoleListPlayers() => _executeListPlayers(readOnlyContext),
    };
  }
}

DebugConsoleExecutionResult _executeGetTileBasicInfo(
  DebugConsoleReadOnlyContext? readOnlyContext,
) {
  final selectedTileKey = readOnlyContext?.selectedTileKey?.trim();
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

DebugConsoleExecutionResult _executeListPlayers(
  DebugConsoleReadOnlyContext? readOnlyContext,
) {
  final players = readOnlyContext?.players;
  if (players == null) {
    return const DebugConsoleExecutionResult.error(
      'Player list is unavailable.',
    );
  }
  final sorted = List<DebugConsolePlayerSnapshot>.of(players)
    ..sort((a, b) => a.id.compareTo(b.id));
  final lines = <String>['players_count: ${sorted.length}', ''];
  for (var i = 0; i < sorted.length; i++) {
    final p = sorted[i];
    final displayName = p.displayName.trim().isEmpty
        ? p.id
        : p.displayName.trim();
    final type = p.isHuman ? 'human' : 'ai';
    final eliminated = p.capitalProvinceId == null;
    lines.addAll([
      'player_id: ${p.id}',
      'display_name: $displayName',
      'type: $type',
      'eliminated: $eliminated',
    ]);
    if (i < sorted.length - 1) {
      lines.add('');
    }
  }
  return DebugConsoleExecutionResult.success(
    events: const [],
    message: lines.join('\n'),
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

String _workerPoolCreditExecutorMessage({
  required String workerTierId,
  required int requestedAmount,
  required int creditedAmount,
}) {
  if (requestedAmount != creditedAmount) {
    return 'Queued debug worker credit ($workerTierId): requested $requestedAmount, '
        'crediting $creditedAmount (clamped to $kDebugConsoleMaxTreasuryCreditAmount).';
  }
  return 'Queued debug worker credit ($workerTierId): $creditedAmount.';
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
