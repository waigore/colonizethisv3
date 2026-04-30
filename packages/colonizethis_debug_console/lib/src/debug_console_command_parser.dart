import 'package:colonizethis_logic/debug_console_api.dart';

import 'debug_console_parsed_invocation.dart';

const int kDebugConsoleMaxSpawnCount = 25;

/// Upper bound for `/add_money` credited amount (parser clamps here).
const int kDebugConsoleMaxTreasuryCreditAmount = 9999;

class DebugConsoleCommandParser {
  const DebugConsoleCommandParser();

  DebugConsoleParseResult parse(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return const DebugConsoleParseResult.error(
        'Enter a slash command. Example: /spawn_civilian explorer 1',
      );
    }
    if (!trimmed.startsWith('/')) {
      return const DebugConsoleParseResult.error(
        'Commands must start with /. Example: /spawn_civilian builder',
      );
    }

    final tokens = trimmed.split(RegExp(r'\s+'));
    final command = tokens.first.toLowerCase();
    return switch (command) {
      '/spawn_civilian' => _parseSpawnCivilian(tokens),
      '/add_money' => _parseAddMoney(tokens),
      '/help' => const DebugConsoleParseResult.error(
        'Supported: /spawn_civilian <explorer|builder|engineer|spy|merchant|rail_builder> [count]; '
        '/add_money <amount> (integer 1..$kDebugConsoleMaxTreasuryCreditAmount; values above '
        '$kDebugConsoleMaxTreasuryCreditAmount are clamped).',
      ),
      _ => DebugConsoleParseResult.error(
        'Unknown command: $command. Try /help.',
      ),
    };
  }

  DebugConsoleParseResult _parseSpawnCivilian(List<String> tokens) {
    if (tokens.length < 2) {
      return const DebugConsoleParseResult.error(
        'Usage: /spawn_civilian <explorer|builder|engineer|spy|merchant|rail_builder> [count]',
      );
    }
    final canonicalUnitType = _unitTypeFromAlias(tokens[1]);
    if (canonicalUnitType == null) {
      return const DebugConsoleParseResult.error(
        'Unknown civilian type. Use explorer, builder, engineer, spy, merchant, or rail_builder.',
      );
    }
    final parsedCount = tokens.length >= 3 ? int.tryParse(tokens[2]) : 1;
    if (parsedCount == null) {
      return const DebugConsoleParseResult.error(
        'Count must be an integer between 1 and 25.',
      );
    }
    if (parsedCount < 1 || parsedCount > kDebugConsoleMaxSpawnCount) {
      return const DebugConsoleParseResult.error(
        'Count must be between 1 and 25.',
      );
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.spawnCivilianAtCapital(
        unitType: canonicalUnitType,
        count: parsedCount,
      ),
    );
  }

  DebugConsoleParseResult _parseAddMoney(List<String> tokens) {
    if (tokens.length < 2) {
      return const DebugConsoleParseResult.error(
        'Usage: /add_money <amount>',
      );
    }
    final rawAmount = int.tryParse(tokens[1]);
    if (rawAmount == null) {
      return const DebugConsoleParseResult.error(
        'Amount must be an integer.',
      );
    }
    if (rawAmount < 1) {
      return const DebugConsoleParseResult.error(
        'Amount must be at least 1.',
      );
    }
    final creditedAmount = rawAmount > kDebugConsoleMaxTreasuryCreditAmount
        ? kDebugConsoleMaxTreasuryCreditAmount
        : rawAmount;
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.treasuryCredit(
        requestedAmount: rawAmount,
        creditedAmount: creditedAmount,
      ),
    );
  }
}

class DebugConsoleParseResult {
  const DebugConsoleParseResult.success(this.invocation)
    : message = null,
      isError = false;

  const DebugConsoleParseResult.error(this.message)
    : invocation = null,
      isError = true;

  final DebugConsoleParsedInvocation? invocation;
  final String? message;
  final bool isError;
}

String? _unitTypeFromAlias(String alias) {
  final normalized = alias.trim().toLowerCase();
  return switch (normalized) {
    'explorer' => kUnitTypeExplorer,
    'builder' => kUnitTypeBuilder,
    'engineer' => kUnitTypeEngineer,
    'spy' => kUnitTypeSpy,
    'merchant' => kUnitTypeMerchant,
    'rail_builder' || 'rail-builder' || 'railbuilder' => kUnitTypeRailBuilder,
    _ => null,
  };
}
