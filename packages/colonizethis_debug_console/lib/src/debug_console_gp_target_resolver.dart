import 'debug_console_command_executor.dart';

/// Resolves a Great Power target for `/observe <target>`.
///
/// [target] is exact `player_id` or case-insensitive `display_name` match.
class DebugConsoleGpTargetResolver {
  const DebugConsoleGpTargetResolver();

  DebugConsoleGpTargetResult resolve({
    required String target,
    required List<DebugConsolePlayerSnapshot> players,
  }) {
    final trimmed = target.trim();
    if (trimmed.isEmpty) {
      return const DebugConsoleGpTargetResult.error(
        'Observe target is required. Use /observe <player_id | display_name> or /observe for global.',
      );
    }

    final sorted = List<DebugConsolePlayerSnapshot>.of(players)
      ..sort((a, b) => a.id.compareTo(b.id));

    final byId = sorted.where((p) => p.id == trimmed).toList();
    if (byId.length == 1) {
      return _validateGp(byId.single);
    }

    final normalized = trimmed.toLowerCase();
    final byName = sorted.where((p) {
      final name = p.displayName.trim();
      final effective = name.isEmpty ? p.id : name;
      return effective.toLowerCase() == normalized;
    }).toList();

    if (byName.length == 1) {
      return _validateGp(byName.single);
    }
    if (byName.length > 1) {
      final ids = byName.map((p) => p.id).toList()..sort();
      return DebugConsoleGpTargetResult.error(
        'Ambiguous observe target "$trimmed". Candidates: ${ids.join(", ")}. '
        'Retry with exact player_id.',
      );
    }

    return DebugConsoleGpTargetResult.error(
      'Unknown observe target "$trimmed". Use /list_players for ids and display names.',
    );
  }

  DebugConsoleGpTargetResult _validateGp(DebugConsolePlayerSnapshot player) {
    if (player.capitalProvinceId == null) {
      return DebugConsoleGpTargetResult.error(
        'Observe target "${player.id}" is eliminated (no capital).',
      );
    }
    return DebugConsoleGpTargetResult.success(player.id);
  }
}

class DebugConsoleGpTargetResult {
  const DebugConsoleGpTargetResult._({
    this.playerId,
    this.errorMessage,
  });

  const DebugConsoleGpTargetResult.success(String playerId)
    : this._(playerId: playerId);

  const DebugConsoleGpTargetResult.error(String message)
    : this._(errorMessage: message);

  final String? playerId;
  final String? errorMessage;

  bool get isSuccess => playerId != null;
}
