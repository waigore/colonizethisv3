import 'package:colonizethis_logic/debug_console_api.dart';

import 'debug_console_parse_result.dart';
import 'debug_console_parser_diplomacy_commands.dart';
import 'debug_console_parser_help.dart';
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
      '/help' => DebugConsoleParseResult.error(buildDebugConsoleHelpMessage()),
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
    final parsed = parseCreditByCanonicalId(
      tokens: tokens,
      usage:
          'Usage: /add_worker <peasants|apprentices|journeymen|masters> <amount>',
      unknownIdMessage:
          'Unknown worker tier. Use peasants, apprentices, journeymen, or masters.',
      candidates: debugConsoleSupportedWorkerTierIds,
    );
    if (parsed.error != null) {
      return DebugConsoleParseResult.error(parsed.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.workerPoolCredit(
        workerTierId: parsed.canonicalId!,
        requestedAmount: parsed.requested,
        creditedAmount: parsed.credited,
      ),
    );
  }

  DebugConsoleParseResult _parseAddResource(List<String> tokens) {
    final parsed = parseCreditByCanonicalId(
      tokens: tokens,
      usage: 'Usage: /add_resource <commodity_id> <amount>',
      unknownIdMessage:
          'Unknown commodity id. Use /help for supported commodity ids.',
      candidates: debugConsoleSupportedCommodityIds,
    );
    if (parsed.error != null) {
      return DebugConsoleParseResult.error(parsed.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.stockpileCredit(
        commodityId: parsed.canonicalId!,
        requestedAmount: parsed.requested,
        creditedAmount: parsed.credited,
      ),
    );
  }

  DebugConsoleParseResult _parseSpawnRegiment(List<String> tokens) {
    final parsed = parseSpawnBySupportedId(
      tokens: tokens,
      usage: 'Usage: /spawn_regiment <regiment_type_id> [count]',
      unknownIdMessage:
          'Unknown regiment type id. Use /help for supported regiment ids.',
      supportedIds: debugConsoleSupportedRegimentTypeIds,
    );
    if (parsed.error != null) {
      return DebugConsoleParseResult.error(parsed.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.spawnRegimentAtCapital(
        regimentTypeId: parsed.typeId!,
        count: parsed.count,
      ),
    );
  }

  DebugConsoleParseResult _parseSpawnShip(List<String> tokens) {
    final parsed = parseSpawnBySupportedId(
      tokens: tokens,
      usage: 'Usage: /spawn_ship <ship_type_id> [count]',
      unknownIdMessage:
          'Unknown ship type id. Use /help for supported ship ids.',
      supportedIds: debugConsoleSupportedShipTypeIds,
    );
    if (parsed.error != null) {
      return DebugConsoleParseResult.error(parsed.error!);
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.spawnShipAtCapitalHomeFleet(
        shipTypeId: parsed.typeId!,
        count: parsed.count,
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
