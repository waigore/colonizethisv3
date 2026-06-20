import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_console_command_parser.dart';
import 'debug_console_executor_helpers.dart';
import 'debug_console_gp_target_resolver.dart';
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
    DebugConsoleGpTargetResolver gpTargetResolver =
        const DebugConsoleGpTargetResolver(),
  }) : _parser = parser,
       _gpTargetResolver = gpTargetResolver;

  final DebugConsoleCommandParser _parser;
  final DebugConsoleGpTargetResolver _gpTargetResolver;

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
    final dispatched = dispatchDebugConsoleSessionEvents(
      invocation,
      humanPlayerId: humanPlayerId,
    );
    if (dispatched != null) {
      return DebugConsoleExecutionResult.success(
        events: dispatched.events,
        message: dispatched.message,
      );
    }

    return switch (invocation) {
      DebugConsoleGetTileBasicInfo() => _executeGetTileBasicInfo(
        readOnlyContext,
      ),
      DebugConsoleListPlayers() => _executeListPlayers(readOnlyContext),
      DebugConsoleSetObserveOff() => DebugConsoleExecutionResult.success(
        events: const [SetObserveModeOffEvent()],
        message: 'Queued observe mode: off.',
      ),
      DebugConsoleSetObserveGlobal() => DebugConsoleExecutionResult.success(
        events: const [SetObserveModeGlobalEvent()],
        message: 'Queued observe mode: global.',
      ),
      DebugConsoleSetObservePlayer(:final target) => _executeSetObservePlayer(
        target,
        readOnlyContext,
      ),
      _ => const DebugConsoleExecutionResult.error('Invalid command.'),
    };
  }

  DebugConsoleExecutionResult _executeSetObservePlayer(
    String target,
    DebugConsoleReadOnlyContext? readOnlyContext,
  ) {
    final players = readOnlyContext?.players;
    if (players == null) {
      return const DebugConsoleExecutionResult.error(
        'Player list is unavailable.',
      );
    }
    final resolved = _gpTargetResolver.resolve(target: target, players: players);
    if (!resolved.isSuccess) {
      return DebugConsoleExecutionResult.error(resolved.errorMessage!);
    }
    final playerId = resolved.playerId!;
    return DebugConsoleExecutionResult.success(
      events: [SetObserveModePlayerEvent(targetPlayerId: playerId)],
      message: 'Queued observe mode: player $playerId.',
    );
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
