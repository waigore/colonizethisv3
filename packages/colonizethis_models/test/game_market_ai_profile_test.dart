import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/minimal_game.dart';

void main() {
  group('Game worldMarketState and aiProfileByGpId', () {
    test('worldMarketState defaults to empty and is omitted from JSON', () {
      final game = minimalGame();
      expect(game.worldMarketState, WorldMarketState.empty);
      expect(game.toJson().containsKey('worldMarketState'), isFalse);
    });

    test('worldMarketState round-trips through JSON when populated', () {
      final marketState = WorldMarketState.withDefaultPrices(const {
        'timber': 30,
        'iron': 80,
      });
      final game = minimalGame(turnNumber: 5, worldMarketState: marketState);
      final restored = Game.fromJson(game.toJson());
      // Post-#3093: prices are stored as integers (floored at persistence
      // boundary per SPEC/game/world-market.md § Price discovery).
      expect(restored.worldMarketState.prices['timber'], 30);
      expect(restored.worldMarketState.prices['iron'], 80);
      expect(restored.worldMarketState.prices['timber'], isA<int>());
      expect(restored.worldMarketState, marketState);
      expect(restored, game);
      expect(restored.hashCode, game.hashCode);
    });

    test('worldMarketState defaults to empty when legacy JSON omits it', () {
      final json = minimalGame().toJson()..remove('worldMarketState');
      final restored = Game.fromJson(json);
      expect(restored.worldMarketState, WorldMarketState.empty);
    });

    test('copyWith replaces worldMarketState', () {
      final game = minimalGame();
      final next = game.copyWith(
        worldMarketState: WorldMarketState.withDefaultPrices(const {
          'timber': 25,
        }),
      );
      // Post-#3093: prices are stored as integers.
      expect(next.worldMarketState.prices['timber'], 25);
      expect(next.worldMarketState.prices['timber'], isA<int>());
      expect(next == game, isFalse);
    });

    // Refs #3444: per-AI-slot blessed tuned-profile selection persistence.
    Game gameWithProfiles(Map<String, String?> aiProfileByGpId) =>
        minimalGame(aiProfileByGpId: aiProfileByGpId);

    test('aiProfileByGpId defaults to empty and is omitted from JSON', () {
      final game = gameWithProfiles(const {});
      expect(game.aiProfileByGpId, isEmpty);
      expect(game.toJson().containsKey('aiProfileByGpId'), isFalse);
    });

    test('aiProfileByGpId round-trips through JSON when populated', () {
      final game = gameWithProfiles(const {
        'france': 'aggressive_v2',
        'england': null,
      });
      final json = game.toJson();
      expect(json.containsKey('aiProfileByGpId'), isTrue);
      final restored = Game.fromJson(json);
      expect(restored.aiProfileByGpId['france'], 'aggressive_v2');
      // null value (normal AI) is preserved for an AI slot key.
      expect(restored.aiProfileByGpId.containsKey('england'), isTrue);
      expect(restored.aiProfileByGpId['england'], isNull);
      expect(restored, game);
    });

    test('aiProfileByGpId legacy saves load as empty (normal AI)', () {
      final json = gameWithProfiles(const {'france': 'aggressive_v2'}).toJson()
        ..remove('aiProfileByGpId');
      final restored = Game.fromJson(json);
      expect(restored.aiProfileByGpId, isEmpty);
    });

    test('aiProfileByGpId tolerates Map<dynamic,dynamic> (Hive typing)', () {
      final json = gameWithProfiles(const {}).toJson();
      json['aiProfileByGpId'] = <dynamic, dynamic>{
        'france': 'defensive_v1',
        'spain': null,
      };
      final restored = Game.fromJson(json);
      expect(restored.aiProfileByGpId['france'], 'defensive_v1');
      expect(restored.aiProfileByGpId['spain'], isNull);
    });

    test('copyWith replaces aiProfileByGpId', () {
      final game = gameWithProfiles(const {'france': 'aggressive_v2'});
      final next = game.copyWith(
        aiProfileByGpId: const {'france': 'defensive_v1'},
      );
      expect(next.aiProfileByGpId['france'], 'defensive_v1');
      expect(next == game, isFalse);
    });

    test('aiProfileByGpId participates in equality', () {
      final a = gameWithProfiles(const {'france': 'aggressive_v2'});
      final b = gameWithProfiles(const {'france': 'aggressive_v2'});
      final c = gameWithProfiles(const {'france': 'defensive_v1'});
      final d = gameWithProfiles(const {'france': null});
      expect(a, b);
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });
  });
}
