import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'debug_console_command_parser_cases.dart';
import 'debug_console_command_parser_leftover_cases.dart';

void main() {
  suppressLogsForTests();

  group('DebugConsoleCommandParser', () {
    const parser = DebugConsoleCommandParser();

    test('spawn and credit parse outcomes', () {
      for (final row in parserSpawnCreditRejectCases) {
        final result = parser.parse(row.input);
        expect(result.isError, isTrue, reason: row.input);
        expect(result.message, contains(row.contains), reason: row.input);
      }
      for (final row in parserSpawnCreditSuccessCases) {
        expectParserCredit(parser.parse(row.input), row);
      }
    });

    test('leftover command parse outcomes', () {
      for (final row in parserLeftoverCommandCases) {
        expectParserLeftover(parser.parse(row.input), row);
      }
    });

    test('help lists spawn, credit, and diplomacy surfaces', () {
      final result = parser.parse('/help');
      expect(result.isError, isTrue);
      final message = result.message ?? '';
      expect(message, contains('/add_worker'));
      expect(message, contains('/add_money'));
      expect(message, contains('9999'));
      expect(message, contains('/reveal_province <regionId|localId'));
      expect(message, contains('/flip_province <regionId|localId>'));
      expect(message, contains('ambiguous'));
      expect(message, contains('/observe\n'));
      expect(message, contains('/observe off'));
      expect(message, contains('/observe <player_id | display_name>'));
      expect(message, contains('/set_diplomacy <faction> <action>'));
      expect(
        message,
        contains('/set_diplomacy <faction_a> <faction_b> <action>'),
      );
      expect(RegExp(r'/get_tile_basic_info').allMatches(message).length, 1);
      expect(RegExp(r'/list_players').allMatches(message).length, 1);
      for (final id in debugConsoleSupportedRegimentTypeIdsSorted) {
        expect(message, contains(id));
      }
      expect(
        message,
        contains(debugConsoleSupportedRegimentTypeIdsSorted.join(', ')),
      );
      for (final id in debugConsoleSupportedShipTypeIdsSorted) {
        expect(message, contains(id));
      }
      expect(
        message,
        contains(debugConsoleSupportedShipTypeIdsSorted.join(', ')),
      );
      for (final id in debugConsoleSupportedCommodityIdsSorted) {
        expect(message, contains(id));
      }
      expect(
        message,
        contains(debugConsoleSupportedCommodityIdsSorted.join(', ')),
      );
      for (final id in ['apprentices', 'journeymen', 'masters', 'peasants']) {
        expect(message, contains(id));
      }
      for (final keyword in DebugDiplomacyActionTokens.sortedKeywords) {
        expect(message, contains(keyword));
      }
    });
  });
}
