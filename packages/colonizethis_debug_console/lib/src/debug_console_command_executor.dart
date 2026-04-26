import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_console_command.dart';
import 'debug_console_command_parser.dart';

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
    final command = parsed.command;
    if (command == null) {
      return const DebugConsoleExecutionResult.error('Invalid command.');
    }
    return _executeCommand(command, humanPlayerId: humanPlayerId);
  }

  DebugConsoleExecutionResult _executeCommand(
    DebugConsoleCommand command, {
    required String humanPlayerId,
  }) {
    return switch (command.kind) {
      DebugConsoleCommandKind.spawnCivilianAtCapital =>
        DebugConsoleExecutionResult.success(
          events: [
            SpawnDebugCivilianAtCapitalEvent(
              humanPlayerId: humanPlayerId,
              unitType: command.unitType,
              count: command.count,
            ),
          ],
          message:
              'Queued debug spawn: ${command.count}x ${command.unitType} at capital.',
        ),
    };
  }
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
