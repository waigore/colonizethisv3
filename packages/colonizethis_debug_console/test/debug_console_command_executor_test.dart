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

    test('emits worker pool credit event for add_worker', () {
      final result = executor.executeRaw(
        rawInput: '/add_worker journeymen 8',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event = result.events.single as CreditDebugWorkerPoolEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.workerTierId, 'journeymen');
      expect(event.requestedAmount, 8);
      expect(event.creditedAmount, 8);
      expect(result.message, contains('journeymen'));
      expect(result.message, contains('8'));
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

    test('executor add_worker clamp message includes both amounts', () {
      final result = executor.executeRaw(
        rawInput: '/add_worker masters 20000',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      final event = result.events.single as CreditDebugWorkerPoolEvent;
      expect(event.workerTierId, 'masters');
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

    test(
      'get_tile_basic_info returns multiline ids from selected tile context',
      () {
        final result = executor.executeRaw(
          rawInput: '/get_tile_basic_info',
          humanPlayerId: 'p1',
          readOnlyContext: const DebugConsoleReadOnlyContext(
            selectedTileKey: 'oldWorld|P12|34|21',
          ),
        );
        expect(result.isError, isFalse);
        expect(result.events, isEmpty);
        expect(
          result.message,
          'tile_id: oldWorld|P12|34|21\nprovince_id: oldWorld|P12',
        );
      },
    );

    test('get_tile_basic_info returns deterministic no-selection error', () {
      final result = executor.executeRaw(
        rawInput: '/get_tile_basic_info',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isTrue);
      expect(result.message, 'No tile is selected.');
      expect(result.events, isEmpty);
    });

    test('get_tile_basic_info rejects malformed selected tile key', () {
      final result = executor.executeRaw(
        rawInput: '/get_tile_basic_info',
        humanPlayerId: 'p1',
        readOnlyContext: const DebugConsoleReadOnlyContext(
          selectedTileKey: 'oldWorld|P12',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.message, 'Selected tile key is invalid.');
      expect(result.events, isEmpty);
    });

    test('existing mutating commands still emit expected event types', () {
      final civilian = executor.executeRaw(
        rawInput: '/spawn_civilian explorer',
        humanPlayerId: 'p1',
      );
      final money = executor.executeRaw(
        rawInput: '/add_money 5',
        humanPlayerId: 'p1',
      );
      final reveal = executor.executeRaw(
        rawInput: '/reveal_province oldWorld|P1',
        humanPlayerId: 'p1',
      );
      expect(civilian.events.single, isA<SpawnDebugCivilianAtCapitalEvent>());
      expect(money.events.single, isA<CreditDebugTreasuryEvent>());
      expect(reveal.events.single, isA<RevealDebugProvinceEvent>());
    });

    test('list_players formats sorted blocks with types and eliminated', () {
      final result = executor.executeRaw(
        rawInput: '/list_players',
        humanPlayerId: 'p1',
        readOnlyContext: DebugConsoleReadOnlyContext(
          players: [
            const DebugConsolePlayerSnapshot(
              id: 'z',
              displayName: 'Zed',
              isHuman: false,
              capitalProvinceId: 'r|P1',
            ),
            const DebugConsolePlayerSnapshot(
              id: 'a',
              displayName: 'Ann',
              isHuman: true,
              capitalProvinceId: 'r|P2',
            ),
          ],
        ),
      );
      expect(result.isError, isFalse);
      expect(result.events, isEmpty);
      expect(result.message, startsWith('players_count: 2'));
      expect(result.message, contains('player_id: a'));
      expect(result.message, contains('display_name: Ann'));
      expect(result.message, contains('type: human'));
      expect(result.message, contains('eliminated: false'));
      expect(result.message, contains('player_id: z'));
      expect(result.message, contains('display_name: Zed'));
      expect(result.message, contains('type: ai'));
      expect(result.message, contains('eliminated: false'));
      final aPos = result.message.indexOf('player_id: a');
      final zPos = result.message.indexOf('player_id: z');
      expect(aPos, lessThan(zPos));
    });

    test('list_players uses id fallback for blank display name', () {
      final result = executor.executeRaw(
        rawInput: '/list_players',
        humanPlayerId: 'p1',
        readOnlyContext: const DebugConsoleReadOnlyContext(
          players: [
            DebugConsolePlayerSnapshot(
              id: 'p_x',
              displayName: '   ',
              isHuman: true,
              capitalProvinceId: null,
            ),
          ],
        ),
      );
      expect(result.isError, isFalse);
      expect(result.events, isEmpty);
      expect(result.message, contains('display_name: p_x'));
      expect(result.message, contains('eliminated: true'));
    });

    test('list_players unavailable when players projection missing', () {
      final result = executor.executeRaw(
        rawInput: '/list_players',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isTrue);
      expect(result.message, 'Player list is unavailable.');
      expect(result.events, isEmpty);
    });

    test('list_players unavailable when context has null players', () {
      final result = executor.executeRaw(
        rawInput: '/list_players',
        humanPlayerId: 'p1',
        readOnlyContext: const DebugConsoleReadOnlyContext(
          selectedTileKey: 'x|y|0|0',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.message, 'Player list is unavailable.');
      expect(result.events, isEmpty);
    });

    test('observe global emits SetObserveModeGlobalEvent', () {
      final result = executor.executeRaw(
        rawInput: '/observe',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events.single, isA<SetObserveModeGlobalEvent>());
    });

    test('observe player resolves display name', () {
      final result = executor.executeRaw(
        rawInput: '/observe France',
        humanPlayerId: 'p1',
        readOnlyContext: DebugConsoleReadOnlyContext(
          players: [
            const DebugConsolePlayerSnapshot(
              id: 'gp2',
              displayName: 'France',
              isHuman: false,
              capitalProvinceId: 'oldWorld|P1',
            ),
          ],
        ),
      );
      expect(result.isError, isFalse);
      final event = result.events.single as SetObserveModePlayerEvent;
      expect(event.targetPlayerId, 'gp2');
    });

    test('observe player rejects eliminated gp', () {
      final result = executor.executeRaw(
        rawInput: '/observe gp3',
        humanPlayerId: 'p1',
        readOnlyContext: DebugConsoleReadOnlyContext(
          players: [
            const DebugConsolePlayerSnapshot(
              id: 'gp3',
              displayName: 'Eliminated',
              isHuman: false,
              capitalProvinceId: null,
            ),
          ],
        ),
      );
      expect(result.isError, isTrue);
      expect(result.message, contains('eliminated'));
      expect(result.events, isEmpty);
    });

    test('observe player rejects unknown target', () {
      final result = executor.executeRaw(
        rawInput: '/observe missing',
        humanPlayerId: 'p1',
        readOnlyContext: const DebugConsoleReadOnlyContext(players: []),
      );
      expect(result.isError, isTrue);
      expect(result.events, isEmpty);
    });

    test('set_diplomacy one-faction form emits event with null factionA', () {
      final result = executor.executeRaw(
        rawInput: '/set_diplomacy Ireland war',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event = result.events.single as SetDebugDiplomacyRelationEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.factionA, isNull);
      expect(event.factionB, 'Ireland');
      expect(event.action, DebugDiplomacyAction.war);
      expect(result.message, contains('war'));
      expect(result.message, contains('Ireland'));
    });

    test('set_diplomacy two-faction form emits event with both factions', () {
      final result = executor.executeRaw(
        rawInput: '/set_diplomacy England France alliance',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      final event = result.events.single as SetDebugDiplomacyRelationEvent;
      expect(event.factionA, 'England');
      expect(event.factionB, 'France');
      expect(event.action, DebugDiplomacyAction.alliance);
      expect(result.message, contains('England'));
      expect(result.message, contains('France'));
    });

    test('set_diplomacy unknown action emits no event', () {
      final result = executor.executeRaw(
        rawInput: '/set_diplomacy Ireland befriend',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isTrue);
      expect(result.events, isEmpty);
    });
  });
}
