import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_console_parser_helpers.dart';

String buildDebugConsoleHelpMessage() {
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
