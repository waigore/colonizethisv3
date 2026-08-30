import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  group('DebugConsoleCommandParser', () {
    const parser = DebugConsoleCommandParser();

    test('parses spawn civilian command with defaults', () {
      final result = parser.parse('/spawn_civilian explorer');
      expect(result.isError, isFalse);
      final spawn = result.invocation! as DebugConsoleSpawnCivilianAtCapital;
      expect(spawn.unitType, kUnitTypeExplorer);
      expect(spawn.count, 1);
    });

    test('parses rail builder aliases', () {
      final result = parser.parse('/spawn_civilian rail_builder 2');
      expect(result.isError, isFalse);
      final spawn = result.invocation! as DebugConsoleSpawnCivilianAtCapital;
      expect(spawn.unitType, kUnitTypeRailBuilder);
      expect(spawn.count, 2);
    });

    test('rejects invalid command', () {
      final result = parser.parse('/unknown');
      expect(result.isError, isTrue);
      expect(result.message, contains('Unknown command'));
    });

    test('spawn and credit parse outcomes', () {
      final rows = <(String input, bool isError, String? contains)>[
        ('/spawn_civilian explorer nope', true, 'Count must be an integer'),
        ('/spawn_civilian explorer 26', true, 'between 1 and 25'),
        ('/add_money abc', true, 'Amount must be an integer'),
        ('/add_money 0', true, 'at least 1'),
        ('/add_worker nobles 1', true, 'Unknown worker tier'),
        ('/add_worker peasants abc', true, 'Amount must be an integer'),
        ('/add_worker peasants 0', true, 'at least 1'),
        ('/add_resource nope 10', true, 'Unknown commodity id'),
        ('/add_resource grain abc', true, 'Amount must be an integer'),
        ('/add_resource grain 0', true, 'at least 1'),
        ('/spawn_regiment nope', true, 'Unknown regiment type id'),
        ('/spawn_ship nope', true, 'Unknown ship type id'),
        ('/spawn_ship carrack 26', true, 'between 1 and 25'),
      ];
      for (final row in rows) {
        final result = parser.parse(row.$1);
        expect(result.isError, row.$2, reason: row.$1);
        if (row.$3 != null) {
          expect(result.message, contains(row.$3!), reason: row.$1);
        }
      }

      final money = parser.parse('/add_money 100');
      expect(money.isError, isFalse);
      final moneyCredit = money.invocation! as DebugConsoleTreasuryCredit;
      expect(moneyCredit.requestedAmount, 100);
      expect(moneyCredit.creditedAmount, 100);

      final clampedMoney = parser.parse('/add_money 12000');
      final clampedTreasury =
          clampedMoney.invocation! as DebugConsoleTreasuryCredit;
      expect(clampedTreasury.requestedAmount, 12000);
      expect(
        clampedTreasury.creditedAmount,
        kDebugConsoleMaxTreasuryCreditAmount,
      );

      final worker = parser.parse('/add_worker PEASANTS 10');
      final workerCredit = worker.invocation! as DebugConsoleWorkerPoolCredit;
      expect(workerCredit.workerTierId, 'peasants');
      expect(workerCredit.requestedAmount, 10);

      final clampedWorker = parser.parse('/add_worker apprentices 12000');
      final clampedPool =
          clampedWorker.invocation! as DebugConsoleWorkerPoolCredit;
      expect(clampedPool.workerTierId, 'apprentices');
      expect(clampedPool.requestedAmount, 12000);
      expect(clampedPool.creditedAmount, kDebugConsoleMaxTreasuryCreditAmount);

      final resource = parser.parse('/add_resource grain 500');
      final stockpile = resource.invocation! as DebugConsoleStockpileCredit;
      expect(stockpile.commodityId, 'grain');
      expect(stockpile.requestedAmount, 500);

      final canonicalResource = parser.parse('/add_resource castIRON 10');
      expect(
        (canonicalResource.invocation! as DebugConsoleStockpileCredit)
            .commodityId,
        'castIron',
      );

      final clampedResource = parser.parse('/add_resource grain 12000');
      final clampedStock =
          clampedResource.invocation! as DebugConsoleStockpileCredit;
      expect(clampedStock.requestedAmount, 12000);
      expect(clampedStock.creditedAmount, kDebugConsoleMaxTreasuryCreditAmount);

      final regiment = parser.parse('/spawn_regiment peasant_levies');
      final regimentSpawn =
          regiment.invocation! as DebugConsoleSpawnRegimentAtCapital;
      expect(regimentSpawn.regimentTypeId, 'peasant_levies');
      expect(regimentSpawn.count, 1);

      final ship = parser.parse('/spawn_ship carrack');
      final shipSpawn =
          ship.invocation! as DebugConsoleSpawnShipAtCapitalHomeFleet;
      expect(shipSpawn.shipTypeId, 'carrack');
      expect(shipSpawn.count, 1);
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

    test('parses flip_province full-id form', () {
      final result = parser.parse('/flip_province oldWorld|P1');
      expect(result.isError, isFalse);
      final flip = result.invocation! as DebugConsoleFlipProvince;
      expect(flip.fullProvinceId, 'oldWorld|P1');
      expect(flip.regionId, isNull);
      expect(flip.provinceDisplayName, isNull);
    });

    test('parses reveal_province full-id form', () {
      final result = parser.parse('/reveal_province oldWorld|P1');
      expect(result.isError, isFalse);
      final reveal = result.invocation! as DebugConsoleRevealProvince;
      expect(reveal.target, 'oldWorld|P1');
      expect(reveal.targetIsFullProvinceId, isTrue);
    });

    test('parses reveal_province display-name form', () {
      final result = parser.parse('/reveal_province New Bordeaux');
      expect(result.isError, isFalse);
      final reveal = result.invocation! as DebugConsoleRevealProvince;
      expect(reveal.target, 'New Bordeaux');
      expect(reveal.targetIsFullProvinceId, isFalse);
    });

    test('rejects reveal_province local id without region prefix', () {
      final result = parser.parse('/reveal_province P1');
      expect(result.isError, isTrue);
      expect(result.message, contains('Use full province id format'));
    });

    test('parses get_tile_basic_info successfully', () {
      final result = parser.parse('/get_tile_basic_info');
      expect(result.isError, isFalse);
      expect(result.invocation, isA<DebugConsoleGetTileBasicInfo>());
    });

    test('rejects get_tile_basic_info extra args with usage', () {
      final result = parser.parse('/get_tile_basic_info extra');
      expect(result.isError, isTrue);
      expect(result.message, 'Usage: /get_tile_basic_info');
    });

    test('parses list_players successfully', () {
      final result = parser.parse('/list_players');
      expect(result.isError, isFalse);
      expect(result.invocation, isA<DebugConsoleListPlayers>());
    });

    test('rejects list_players extra args with usage', () {
      final result = parser.parse('/list_players foo');
      expect(result.isError, isTrue);
      expect(result.message, 'Usage: /list_players');
    });

    test('parses /observe as global mode', () {
      final result = parser.parse('/observe');
      expect(result.isError, isFalse);
      expect(result.invocation, isA<DebugConsoleSetObserveGlobal>());
    });

    test('parses /observe off', () {
      final result = parser.parse('/observe off');
      expect(result.isError, isFalse);
      expect(result.invocation, isA<DebugConsoleSetObserveOff>());
    });

    test('parses /observe with display name target', () {
      final result = parser.parse('/observe France');
      expect(result.isError, isFalse);
      final inv = result.invocation! as DebugConsoleSetObservePlayer;
      expect(inv.target, 'France');
    });

    test('parses /set_diplomacy one-faction form', () {
      final result = parser.parse('/set_diplomacy Ireland war');
      expect(result.isError, isFalse);
      final inv = result.invocation! as DebugConsoleSetDiplomacy;
      expect(inv.factionA, isNull);
      expect(inv.factionB, 'Ireland');
      expect(inv.action, DebugDiplomacyAction.war);
    });

    test('parses /set_diplomacy two-faction form', () {
      final result = parser.parse('/set_diplomacy England France alliance');
      expect(result.isError, isFalse);
      final inv = result.invocation! as DebugConsoleSetDiplomacy;
      expect(inv.factionA, 'England');
      expect(inv.factionB, 'France');
      expect(inv.action, DebugDiplomacyAction.alliance);
    });

    test('parses /set_diplomacy multi-word quoted faction name', () {
      final result = parser.parse('/set_diplomacy "Zulu Kingdom" war');
      expect(result.isError, isFalse);
      final inv = result.invocation! as DebugConsoleSetDiplomacy;
      expect(inv.factionA, isNull);
      expect(inv.factionB, 'Zulu Kingdom');
      expect(inv.action, DebugDiplomacyAction.war);
    });

    test('parses /set_diplomacy snake_case action keyword', () {
      final result = parser.parse('/set_diplomacy England France no_alliance');
      expect(result.isError, isFalse);
      final inv = result.invocation! as DebugConsoleSetDiplomacy;
      expect(inv.action, DebugDiplomacyAction.noAlliance);
    });

    test('parses /set_diplomacy action keyword case-insensitively', () {
      final result = parser.parse('/set_diplomacy Ireland JOIN_EMPIRE');
      expect(result.isError, isFalse);
      final inv = result.invocation! as DebugConsoleSetDiplomacy;
      expect(inv.action, DebugDiplomacyAction.joinEmpire);
    });

    test('rejects /set_diplomacy with unknown action', () {
      final result = parser.parse('/set_diplomacy Ireland befriend');
      expect(result.isError, isTrue);
      expect(result.message, contains('Unknown diplomacy action'));
    });

    test('rejects /set_diplomacy with no action token', () {
      final result = parser.parse('/set_diplomacy Ireland');
      expect(result.isError, isTrue);
      expect(result.message, contains('Usage: /set_diplomacy'));
    });

    test('rejects /set_diplomacy with too many faction tokens', () {
      final result = parser.parse('/set_diplomacy A B C war');
      expect(result.isError, isTrue);
      expect(result.message, contains('Usage: /set_diplomacy'));
    });
  });
}
