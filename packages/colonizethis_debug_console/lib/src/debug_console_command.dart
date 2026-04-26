class DebugConsoleCommand {
  const DebugConsoleCommand.spawnCivilian({
    required this.unitType,
    required this.count,
  }) : kind = DebugConsoleCommandKind.spawnCivilianAtCapital;

  final DebugConsoleCommandKind kind;
  final String unitType;
  final int count;
}

enum DebugConsoleCommandKind { spawnCivilianAtCapital }
