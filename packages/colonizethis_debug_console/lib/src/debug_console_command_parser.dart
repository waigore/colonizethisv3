import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_console_parse_result.dart';
import 'debug_console_parser_diplomacy_commands.dart';
import 'debug_console_parser_helpers.dart';
import 'debug_console_parser_province_commands.dart';
import 'debug_console_parsed_invocation.dart';

export 'debug_console_parse_result.dart';
export 'debug_console_parser_helpers.dart'
    show kDebugConsoleMaxSpawnCount, kDebugConsoleMaxTreasuryCreditAmount;

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
      '/spawn_regiment' => _parseSpawnRegiment(tokens),
      '/spawn_ship' => _parseSpawnShip(tokens),
      '/add_money' => _parseAddMoney(tokens),
      '/add_worker' => _parseAddWorker(tokens),
      '/add_resource' => _parseAddResource(tokens),
      '/flip_province' => parseFlipProvinceCommand(tokens),
      '/reveal_province' => parseRevealProvinceCommand(tokens),
      '/get_tile_basic_info' => _parseGetTileBasicInfo(tokens),
      '/list_players' => _parseListPlayers(tokens),
      '/observe' => parseObserveCommand(tokens),
      '/set_diplomacy' => parseSetDiplomacyCommand(trimmed),
      '/help' => DebugConsoleParseResult.error(_buildHelpMessage()),
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
    final countResult = parseOptionalCount(tokens, 3);
    if (countResult.error != null) {
      return DebugConsoleParseResult.error(countResult.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.spawnCivilianAtCapital(
        unitType: canonicalUnitType,
        count: countResult.count,
      ),
    );
  }

  DebugConsoleParseResult _parseAddMoney(List<String> tokens) {
    if (tokens.length < 2) {
      return const DebugConsoleParseResult.error('Usage: /add_money <amount>');
    }
    final amountResult = parseAmountWithClamp(tokens[1]);
    if (amountResult.error != null) {
      return DebugConsoleParseResult.error(amountResult.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.treasuryCredit(
        requestedAmount: amountResult.requested,
        creditedAmount: amountResult.credited,
      ),
    );
  }

  DebugConsoleParseResult _parseAddWorker(List<String> tokens) {
    if (tokens.length < 3) {
      return const DebugConsoleParseResult.error(
        'Usage: /add_worker <peasants|apprentices|journeymen|masters> <amount>',
      );
    }
    final tierInput = tokens[1].trim().toLowerCase();
    final canonicalTierId = canonicalIdForInput(
      tierInput,
      debugConsoleSupportedWorkerTierIds,
    );
    if (canonicalTierId == null) {
      return const DebugConsoleParseResult.error(
        'Unknown worker tier. Use peasants, apprentices, journeymen, or masters.',
      );
    }
    final amountResult = parseAmountWithClamp(tokens[2]);
    if (amountResult.error != null) {
      return DebugConsoleParseResult.error(amountResult.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.workerPoolCredit(
        workerTierId: canonicalTierId,
        requestedAmount: amountResult.requested,
        creditedAmount: amountResult.credited,
      ),
    );
  }

  DebugConsoleParseResult _parseAddResource(List<String> tokens) {
    if (tokens.length < 3) {
      return const DebugConsoleParseResult.error(
        'Usage: /add_resource <commodity_id> <amount>',
      );
    }
    final requestedCommodityId = tokens[1].trim();
    final normalizedCommodityId = requestedCommodityId.toLowerCase();
    final canonicalCommodityId = canonicalIdForInput(
      normalizedCommodityId,
      debugConsoleSupportedCommodityIds,
    );
    if (canonicalCommodityId == null) {
      return const DebugConsoleParseResult.error(
        'Unknown commodity id. Use /help for supported commodity ids.',
      );
    }
    final amountResult = parseAmountWithClamp(tokens[2]);
    if (amountResult.error != null) {
      return DebugConsoleParseResult.error(amountResult.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.stockpileCredit(
        commodityId: canonicalCommodityId,
        requestedAmount: amountResult.requested,
        creditedAmount: amountResult.credited,
      ),
    );
  }

  DebugConsoleParseResult _parseSpawnRegiment(List<String> tokens) {
    if (tokens.length < 2) {
      return const DebugConsoleParseResult.error(
        'Usage: /spawn_regiment <regiment_type_id> [count]',
      );
    }
    final regimentTypeId = tokens[1].trim().toLowerCase();
    if (!debugConsoleSupportedRegimentTypeIds.contains(regimentTypeId)) {
      return const DebugConsoleParseResult.error(
        'Unknown regiment type id. Use /help for supported regiment ids.',
      );
    }
    final countResult = parseOptionalCount(tokens, 3);
    if (countResult.error != null) {
      return DebugConsoleParseResult.error(countResult.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.spawnRegimentAtCapital(
        regimentTypeId: regimentTypeId,
        count: countResult.count,
      ),
    );
  }

  DebugConsoleParseResult _parseSpawnShip(List<String> tokens) {
    if (tokens.length < 2) {
      return const DebugConsoleParseResult.error(
        'Usage: /spawn_ship <ship_type_id> [count]',
      );
    }
    final shipTypeId = tokens[1].trim().toLowerCase();
    if (!debugConsoleSupportedShipTypeIds.contains(shipTypeId)) {
      return const DebugConsoleParseResult.error(
        'Unknown ship type id. Use /help for supported ship ids.',
      );
    }
    final countResult = parseOptionalCount(tokens, 3);
    if (countResult.error != null) {
      return DebugConsoleParseResult.error(countResult.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.spawnShipAtCapitalHomeFleet(
        shipTypeId: shipTypeId,
        count: countResult.count,
      ),
    );
  }

  DebugConsoleParseResult _parseGetTileBasicInfo(List<String> tokens) {
    if (tokens.length != 1) {
      return const DebugConsoleParseResult.error('Usage: /get_tile_basic_info');
    }
    return const DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.getTileBasicInfo(),
    );
  }

  DebugConsoleParseResult _parseListPlayers(List<String> tokens) {
    if (tokens.length != 1) {
      return const DebugConsoleParseResult.error('Usage: /list_players');
    }
    return const DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.listPlayers(),
    );
  }

}

String _buildHelpMessage() {
  final regimentIds = debugConsoleSupportedRegimentTypeIdsSorted.join(', ');
  final shipIds = debugConsoleSupportedShipTypeIdsSorted.join(', ');
  final commodityIds = debugConsoleSupportedCommodityIdsSorted.join(', ');
  final workerTierIds = debugConsoleSupportedWorkerTierIdsSorted.join(', ');
  final diplomacyActions = DebugDiplomacyActionTokens.sortedKeywords.join(', ');
  return 'Supported commands:\n'
      '- /spawn_civilian <explorer|builder|engineer|spy|merchant|rail_builder> [count]\n'
      '- /spawn_regiment <regiment_type_id> [count]\n'
      '  supported ids: $regimentIds\n'
      '- /spawn_ship <ship_type_id> [count]\n'
      '  supported ids: $shipIds\n'
      '- /add_money <amount>\n'
      '  integer 1..$kDebugConsoleMaxTreasuryCreditAmount; values above '
      '$kDebugConsoleMaxTreasuryCreditAmount are clamped\n'
      '- /add_worker <peasants|apprentices|journeymen|masters> <amount>\n'
      '  supported tier ids: $workerTierIds\n'
      '  integer 1..$kDebugConsoleMaxTreasuryCreditAmount; values above '
      '$kDebugConsoleMaxTreasuryCreditAmount are clamped\n'
      '- /add_resource <commodity_id> <amount>\n'
      '  supported ids: $commodityIds\n'
      '  integer 1..$kDebugConsoleMaxTreasuryCreditAmount; values above '
      '$kDebugConsoleMaxTreasuryCreditAmount are clamped\n'
      '- /flip_province <regionId> <province_display_name>\n'
      '- /flip_province <regionId|localId>\n'
      '- /reveal_province <regionId|localId | province_display_name>\n'
      '- /get_tile_basic_info\n'
      '  if name is ambiguous, retry with full province id.\n'
      '- /list_players\n'
      '- /observe\n'
      '- /observe off\n'
      '- /observe <player_id | display_name>\n'
      '- /set_diplomacy <faction> <action>\n'
      '- /set_diplomacy <faction_a> <faction_b> <action>\n'
      '  supported actions: $diplomacyActions';
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
