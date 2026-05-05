import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('DebugConsoleCommandExecutor', () {
    const executor = DebugConsoleCommandExecutor();

    test('emits spawn event for valid command', () {
      final result = executor.executeRaw(
        rawInput: '/spawn_civilian builder 3',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event = result.events.single as SpawnDebugCivilianAtCapitalEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.unitType, kUnitTypeBuilder);
      expect(event.count, 3);
    });

    test('emits treasury credit event for add_money', () {
      final result = executor.executeRaw(
        rawInput: '/add_money 500',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event = result.events.single as CreditDebugTreasuryEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.requestedAmount, 500);
      expect(event.creditedAmount, 500);
      expect(result.message, contains('500'));
    });

    test('emits stockpile credit event for add_resource', () {
      final result = executor.executeRaw(
        rawInput: '/add_resource grain 500',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event = result.events.single as CreditDebugStockpileCommodityEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.commodityId, 'grain');
      expect(event.requestedAmount, 500);
      expect(event.creditedAmount, 500);
      expect(result.message, contains('grain'));
      expect(result.message, contains('500'));
    });

    test('executor add_resource clamp message includes both amounts', () {
      final result = executor.executeRaw(
        rawInput: '/add_resource castIron 20000',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      final event = result.events.single as CreditDebugStockpileCommodityEvent;
      expect(event.commodityId, 'castIron');
      expect(event.requestedAmount, 20000);
      expect(event.creditedAmount, kDebugConsoleMaxTreasuryCreditAmount);
      expect(result.message, contains('20000'));
      expect(result.message, contains('9999'));
    });

    test('emits spawn regiment event for valid command', () {
      final result = executor.executeRaw(
        rawInput: '/spawn_regiment peasant_levies 2',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event = result.events.single as SpawnDebugRegimentAtCapitalEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.regimentTypeId, 'peasant_levies');
      expect(event.count, 2);
      expect(result.message, contains('peasant_levies'));
    });

    test('emits spawn ship event for valid command', () {
      final result = executor.executeRaw(
        rawInput: '/spawn_ship carrack 2',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event =
          result.events.single as SpawnDebugShipAtCapitalHomeFleetEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.shipTypeId, 'carrack');
      expect(event.count, 2);
      expect(result.message, contains('carrack'));
    });

    test('executor message for clamped add_money includes both amounts', () {
      final result = executor.executeRaw(
        rawInput: '/add_money 20000',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      final event = result.events.single as CreditDebugTreasuryEvent;
      expect(event.requestedAmount, 20000);
      expect(event.creditedAmount, kDebugConsoleMaxTreasuryCreditAmount);
      expect(result.message, contains('20000'));
      expect(result.message, contains('9999'));
    });

    test('returns error for invalid command', () {
      final result = executor.executeRaw(rawInput: '/bad', humanPlayerId: 'p1');
      expect(result.isError, isTrue);
      expect(result.events, isEmpty);
    });

    test('emits flip_province event for valid command', () {
      final result = executor.executeRaw(
        rawInput: '/flip_province oldWorld New Bordeaux',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event = result.events.single as FlipDebugProvinceOwnershipEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.regionId, 'oldWorld');
      expect(event.provinceDisplayName, 'New Bordeaux');
    });

    test('emits flip_province event for full-id form', () {
      final result = executor.executeRaw(
        rawInput: '/flip_province oldWorld|P1',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      final event = result.events.single as FlipDebugProvinceOwnershipEvent;
      expect(event.fullProvinceId, 'oldWorld|P1');
      expect(event.regionId, isNull);
      expect(event.provinceDisplayName, isNull);
    });

    test('emits reveal_province event', () {
      final result = executor.executeRaw(
        rawInput: '/reveal_province oldWorld|P1',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      final event = result.events.single as RevealDebugProvinceEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.target, 'oldWorld|P1');
      expect(event.targetIsFullProvinceId, isTrue);
    });
  });
}
