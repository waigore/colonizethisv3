import 'package:colonizethis_models/colonizethis_models.dart';

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
