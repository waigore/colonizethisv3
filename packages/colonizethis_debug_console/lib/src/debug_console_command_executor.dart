import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_console_command_parser.dart';
import 'debug_console_parsed_invocation.dart';

class DebugConsoleCommandExecutor {
  const DebugConsoleCommandExecutor({
    DebugConsoleCommandParser parser = const DebugConsoleCommandParser(),
  }) : _parser = parser;

  final DebugConsoleCommandParser _parser;

  DebugConsoleExecutionResult executeRaw({
    required String rawInput,
    required String humanPlayerId,
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
    return _executeInvocation(invocation, humanPlayerId: humanPlayerId);
  }

  DebugConsoleExecutionResult _executeInvocation(
    DebugConsoleParsedInvocation invocation, {
    required String humanPlayerId,
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
          message:
              'Queued debug spawn: ${count}x $unitType at capital.',
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
    };
  }
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
