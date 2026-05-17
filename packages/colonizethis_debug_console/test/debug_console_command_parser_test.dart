import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  group('DebugConsoleCommandParser', () {
    const parser = DebugConsoleCommandParser();

    test('parses spawn civilian command with defaults', () {
      final result = parser.parse('/spawn_civilian explorer');
      expect(result.isError, isFalse);
      expect(result.invocation, isNotNull);
      final inv = result.invocation!;
      expect(inv, isA<DebugConsoleSpawnCivilianAtCapital>());
      final spawn = inv as DebugConsoleSpawnCivilianAtCapital;
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

    test('rejects non-integer spawn count', () {
      final result = parser.parse('/spawn_civilian explorer nope');
      expect(result.isError, isTrue);
      expect(result.message, contains('Count must be an integer'));
    });

    test('rejects spawn count above max limit', () {
      final result = parser.parse('/spawn_civilian explorer 26');
      expect(result.isError, isTrue);
      expect(result.message, contains('between 1 and 25'));
    });

    test('parses add_money with equal requested and credited', () {
      final result = parser.parse('/add_money 100');
      expect(result.isError, isFalse);
      final credit = result.invocation! as DebugConsoleTreasuryCredit;
      expect(credit.requestedAmount, 100);
      expect(credit.creditedAmount, 100);
    });

    test('clamps add_money above cap in parser', () {
      final result = parser.parse('/add_money 12000');
      expect(result.isError, isFalse);
      final credit = result.invocation! as DebugConsoleTreasuryCredit;
      expect(credit.requestedAmount, 12000);
      expect(credit.creditedAmount, kDebugConsoleMaxTreasuryCreditAmount);
    });

    test('rejects non-integer add_money amount', () {
      final result = parser.parse('/add_money abc');
      expect(result.isError, isTrue);
      expect(result.message, contains('Amount must be an integer'));
    });

    test('rejects add_money below 1', () {
      final result = parser.parse('/add_money 0');
      expect(result.isError, isTrue);
      expect(result.message, contains('at least 1'));
    });

    test('parses add_worker with canonical tier after case-insensitive input', () {
      final result = parser.parse('/add_worker PEASANTS 10');
      expect(result.isError, isFalse);
      final credit = result.invocation! as DebugConsoleWorkerPoolCredit;
      expect(credit.workerTierId, 'peasants');
      expect(credit.requestedAmount, 10);
      expect(credit.creditedAmount, 10);
    });

    test('rejects add_worker unknown tier', () {
      final result = parser.parse('/add_worker nobles 1');
      expect(result.isError, isTrue);
      expect(result.message, contains('Unknown worker tier'));
    });

    test('rejects add_worker non-integer amount', () {
      final result = parser.parse('/add_worker peasants abc');
      expect(result.isError, isTrue);
      expect(result.message, contains('Amount must be an integer'));
    });

    test('rejects add_worker amount below 1', () {
      final result = parser.parse('/add_worker peasants 0');
      expect(result.isError, isTrue);
      expect(result.message, contains('at least 1'));
    });

    test('clamps add_worker above cap in parser', () {
      final result = parser.parse('/add_worker apprentices 12000');
      expect(result.isError, isFalse);
      final credit = result.invocation! as DebugConsoleWorkerPoolCredit;
      expect(credit.workerTierId, 'apprentices');
      expect(credit.requestedAmount, 12000);
      expect(credit.creditedAmount, kDebugConsoleMaxTreasuryCreditAmount);
    });

    test('help lists add_worker tier ids', () {
      final result = parser.parse('/help');
      expect(result.isError, isTrue);
      expect(result.message, contains('/add_worker'));
      expect(result.message, contains('apprentices'));
      expect(result.message, contains('journeymen'));
      expect(result.message, contains('masters'));
      expect(result.message, contains('peasants'));
    });

    test('help lists add_money bounds', () {
      final result = parser.parse('/help');
      expect(result.isError, isTrue);
      expect(result.message, contains('/add_money'));
      expect(result.message, contains('9999'));
    });

    test('parses add_resource with canonical commodity id', () {
      final result = parser.parse('/add_resource grain 500');
      expect(result.isError, isFalse);
      final credit = result.invocation! as DebugConsoleStockpileCredit;
      expect(credit.commodityId, 'grain');
      expect(credit.requestedAmount, 500);
      expect(credit.creditedAmount, 500);
    });

    test('parses add_resource case-insensitively and emits canonical id', () {
      final result = parser.parse('/add_resource castIRON 10');
      expect(result.isError, isFalse);
      final credit = result.invocation! as DebugConsoleStockpileCredit;
      expect(credit.commodityId, 'castIron');
      expect(credit.requestedAmount, 10);
      expect(credit.creditedAmount, 10);
    });

    test('clamps add_resource above cap in parser', () {
      final result = parser.parse('/add_resource grain 12000');
      expect(result.isError, isFalse);
      final credit = result.invocation! as DebugConsoleStockpileCredit;
      expect(credit.requestedAmount, 12000);
      expect(credit.creditedAmount, kDebugConsoleMaxTreasuryCreditAmount);
    });

    test('rejects add_resource unknown commodity id', () {
      final result = parser.parse('/add_resource nope 10');
      expect(result.isError, isTrue);
      expect(result.message, contains('Unknown commodity id'));
    });

    test('rejects add_resource invalid amount input', () {
      final result = parser.parse('/add_resource grain abc');
      expect(result.isError, isTrue);
      expect(result.message, contains('Amount must be an integer'));
    });

    test('rejects add_resource amount below 1', () {
      final result = parser.parse('/add_resource grain 0');
      expect(result.isError, isTrue);
      expect(result.message, contains('at least 1'));
    });

    test('parses spawn regiment command with defaults', () {
      final result = parser.parse('/spawn_regiment peasant_levies');
      expect(result.isError, isFalse);
      final spawn = result.invocation! as DebugConsoleSpawnRegimentAtCapital;
      expect(spawn.regimentTypeId, 'peasant_levies');
      expect(spawn.count, 1);
    });

    test('rejects unknown regiment id', () {
      final result = parser.parse('/spawn_regiment nope');
      expect(result.isError, isTrue);
      expect(result.message, contains('Unknown regiment type id'));
    });

    test('parses spawn ship command with defaults', () {
      final result = parser.parse('/spawn_ship carrack');
      expect(result.isError, isFalse);
      final spawn =
          result.invocation! as DebugConsoleSpawnShipAtCapitalHomeFleet;
      expect(spawn.shipTypeId, 'carrack');
      expect(spawn.count, 1);
    });

    test('rejects unknown ship id', () {
      final result = parser.parse('/spawn_ship nope');
      expect(result.isError, isTrue);
      expect(result.message, contains('Unknown ship type id'));
    });

    test('rejects spawn ship count above max limit', () {
      final result = parser.parse('/spawn_ship carrack 26');
      expect(result.isError, isTrue);
      expect(result.message, contains('between 1 and 25'));
    });

    test('help includes all regiment ids in stable order', () {
      final result = parser.parse('/help');
      final message = result.message ?? '';
      final sorted = debugConsoleSupportedRegimentTypeIdsSorted;
      for (final id in sorted) {
        expect(message, contains(id));
      }
      final joined = sorted.join(', ');
      expect(message, contains(joined));
    });

    test('help includes all ship ids in stable order', () {
      final result = parser.parse('/help');
      final message = result.message ?? '';
      final sorted = debugConsoleSupportedShipTypeIdsSorted;
      for (final id in sorted) {
        expect(message, contains(id));
      }
      final joined = sorted.join(', ');
      expect(message, contains(joined));
    });

    test('help includes all commodity ids in stable order', () {
      final result = parser.parse('/help');
      final message = result.message ?? '';
      final sorted = debugConsoleSupportedCommodityIdsSorted;
      for (final id in sorted) {
        expect(message, contains(id));
      }
      final joined = sorted.join(', ');
      expect(message, contains(joined));
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

    test('help includes reveal_province usage and flip full-id retry form', () {
      final result = parser.parse('/help');
      final message = result.message ?? '';
      expect(message, contains('/reveal_province <regionId|localId'));
      expect(message, contains('/flip_province <regionId|localId>'));
      expect(message, contains('ambiguous'));
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

    test('help includes get_tile_basic_info exactly once', () {
      final result = parser.parse('/help');
      final message = result.message ?? '';
      final matches = RegExp(
        r'/get_tile_basic_info',
      ).allMatches(message).length;
      expect(matches, 1);
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

    test('help includes list_players exactly once', () {
      final result = parser.parse('/help');
      final message = result.message ?? '';
      final matches = RegExp(r'/list_players').allMatches(message).length;
      expect(matches, 1);
    });
  });
}
