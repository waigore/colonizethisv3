import 'package:colonizethis_logic/debug_console_api.dart';

import 'debug_console_parsed_invocation.dart';

const int kDebugConsoleMaxSpawnCount = 25;

/// Upper bound for `/add_money` credited amount (parser clamps here).
const int kDebugConsoleMaxTreasuryCreditAmount = 9999;
final RegExp _localProvinceIdPattern = RegExp(r'^P[0-9]+$');

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
      '/flip_province' => _parseFlipProvince(tokens),
      '/reveal_province' => _parseRevealProvince(tokens),
      '/get_tile_basic_info' => _parseGetTileBasicInfo(tokens),
      '/list_players' => _parseListPlayers(tokens),
      '/observe' => _parseObserve(tokens),
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
      return const DebugConsoleParseResult.error('Usage: /add_money <amount>');
    }
    final rawAmount = int.tryParse(tokens[1]);
    if (rawAmount == null) {
      return const DebugConsoleParseResult.error('Amount must be an integer.');
    }
    if (rawAmount < 1) {
      return const DebugConsoleParseResult.error('Amount must be at least 1.');
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

  DebugConsoleParseResult _parseAddWorker(List<String> tokens) {
    if (tokens.length < 3) {
      return const DebugConsoleParseResult.error(
        'Usage: /add_worker <peasants|apprentices|journeymen|masters> <amount>',
      );
    }
    final tierInput = tokens[1].trim().toLowerCase();
    final canonicalTierId = _canonicalWorkerTierIdForInput(tierInput);
    if (canonicalTierId == null) {
      return const DebugConsoleParseResult.error(
        'Unknown worker tier. Use peasants, apprentices, journeymen, or masters.',
      );
    }
    final rawAmount = int.tryParse(tokens[2]);
    if (rawAmount == null) {
      return const DebugConsoleParseResult.error('Amount must be an integer.');
    }
    if (rawAmount < 1) {
      return const DebugConsoleParseResult.error('Amount must be at least 1.');
    }
    final creditedAmount = rawAmount > kDebugConsoleMaxTreasuryCreditAmount
        ? kDebugConsoleMaxTreasuryCreditAmount
        : rawAmount;
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.workerPoolCredit(
        workerTierId: canonicalTierId,
        requestedAmount: rawAmount,
        creditedAmount: creditedAmount,
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
    final canonicalCommodityId = _canonicalCommodityIdForInput(
      normalizedCommodityId,
    );
    if (canonicalCommodityId == null) {
      return const DebugConsoleParseResult.error(
        'Unknown commodity id. Use /help for supported commodity ids.',
      );
    }
    final rawAmount = int.tryParse(tokens[2]);
    if (rawAmount == null) {
      return const DebugConsoleParseResult.error('Amount must be an integer.');
    }
    if (rawAmount < 1) {
      return const DebugConsoleParseResult.error('Amount must be at least 1.');
    }
    final creditedAmount = rawAmount > kDebugConsoleMaxTreasuryCreditAmount
        ? kDebugConsoleMaxTreasuryCreditAmount
        : rawAmount;
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.stockpileCredit(
        commodityId: canonicalCommodityId,
        requestedAmount: rawAmount,
        creditedAmount: creditedAmount,
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
      DebugConsoleParsedInvocation.spawnRegimentAtCapital(
        regimentTypeId: regimentTypeId,
        count: parsedCount,
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
      DebugConsoleParsedInvocation.spawnShipAtCapitalHomeFleet(
        shipTypeId: shipTypeId,
        count: parsedCount,
      ),
    );
  }

  DebugConsoleParseResult _parseFlipProvince(List<String> tokens) {
    if (tokens.length == 2) {
      final fullProvinceId = tokens[1].trim();
      if (!_looksLikePrefixedProvinceId(fullProvinceId)) {
        return const DebugConsoleParseResult.error(
          'Usage: /flip_province <regionId> <province_display_name> OR /flip_province <regionId|localId>',
        );
      }
      return DebugConsoleParseResult.success(
        DebugConsoleParsedInvocation.flipProvince(
          fullProvinceId: fullProvinceId,
        ),
      );
    }
    if (tokens.length < 3) {
      return const DebugConsoleParseResult.error(
        'Usage: /flip_province <regionId> <province_display_name> OR /flip_province <regionId|localId>',
      );
    }
    final regionId = tokens[1].trim();
    if (regionId.isEmpty) {
      return const DebugConsoleParseResult.error(
        'Region id must not be empty.',
      );
    }
    final provinceDisplayName = tokens.sublist(2).join(' ').trim();
    if (provinceDisplayName.isEmpty) {
      return const DebugConsoleParseResult.error(
        'Province display name must not be empty.',
      );
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.flipProvince(
        regionId: regionId,
        provinceDisplayName: provinceDisplayName,
      ),
    );
  }

  DebugConsoleParseResult _parseRevealProvince(List<String> tokens) {
    if (tokens.length < 2) {
      return const DebugConsoleParseResult.error(
        'Usage: /reveal_province <regionId|localId | province_display_name>',
      );
    }
    final target = tokens.sublist(1).join(' ').trim();
    if (target.isEmpty) {
      return const DebugConsoleParseResult.error(
        'Usage: /reveal_province <regionId|localId | province_display_name>',
      );
    }
    if (_localProvinceIdPattern.hasMatch(target)) {
      return const DebugConsoleParseResult.error(
        'Use full province id format: regionId|localId',
      );
    }
    final targetIsFullProvinceId = _looksLikePrefixedProvinceId(target);
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.revealProvince(
        target: target,
        targetIsFullProvinceId: targetIsFullProvinceId,
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

  DebugConsoleParseResult _parseObserve(List<String> tokens) {
    if (tokens.length == 1) {
      return const DebugConsoleParseResult.success(
        DebugConsoleParsedInvocation.setObserveGlobal(),
      );
    }
    if (tokens.length == 2 && tokens[1].toLowerCase() == 'off') {
      return const DebugConsoleParseResult.success(
        DebugConsoleParsedInvocation.setObserveOff(),
      );
    }
    if (tokens.length >= 2) {
      final target = tokens.sublist(1).join(' ');
      return DebugConsoleParseResult.success(
        DebugConsoleParsedInvocation.setObservePlayer(target: target),
      );
    }
    return const DebugConsoleParseResult.error(
      'Usage: /observe | /observe off | /observe <player_id | display_name>',
    );
  }
}

String? _canonicalCommodityIdForInput(String normalizedInput) {
  for (final candidate in debugConsoleSupportedCommodityIds) {
    if (candidate.toLowerCase() == normalizedInput) {
      return candidate;
    }
  }
  return null;
}

String? _canonicalWorkerTierIdForInput(String normalizedInput) {
  for (final candidate in debugConsoleSupportedWorkerTierIds) {
    if (candidate.toLowerCase() == normalizedInput) {
      return candidate;
    }
  }
  return null;
}

String _buildHelpMessage() {
  final regimentIds = debugConsoleSupportedRegimentTypeIdsSorted.join(', ');
  final shipIds = debugConsoleSupportedShipTypeIdsSorted.join(', ');
  final commodityIds = debugConsoleSupportedCommodityIdsSorted.join(', ');
  final workerTierIds = debugConsoleSupportedWorkerTierIdsSorted.join(', ');
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
      '- /observe <player_id | display_name>';
}

bool _looksLikePrefixedProvinceId(String value) {
  final separator = value.indexOf('|');
  if (separator <= 0 || separator == value.length - 1) {
    return false;
  }
  return true;
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
