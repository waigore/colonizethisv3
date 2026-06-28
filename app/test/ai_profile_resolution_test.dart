import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_app/core/services/ai_profile_resolution.dart';

void main() {
  group('resolveAiProfilesForGame', () {
    test('returns null when game has no profile selections', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      expect(
        resolveAiProfilesForGame(game, seedAiProfilesById),
        isNull,
      );
    });

    test('resolves known profile names by gpId', () {
      final victoria = seedAiProfilesById['victoria']!;
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
        aiProfileByGpId: const {'gp2': 'victoria'},
      );
      final resolved = resolveAiProfilesForGame(
        game,
        <String, AiProfile>{'victoria': victoria},
      );
      expect(resolved, isNotNull);
      expect(resolved!['gp2'], victoria);
    });

    test('skips missing profile names with warning path', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
        aiProfileByGpId: const {'gp2': 'removed_profile'},
      );
      expect(
        resolveAiProfilesForGame(game, const {}),
        isNull,
      );
    });

    test('skips null/empty profile-name values (normal AI slots)', () {
      final victoria = seedAiProfilesById['victoria']!;
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
        aiProfileByGpId: const {'gp1': null, 'gp2': '', 'gp3': 'victoria'},
      );
      final resolved = resolveAiProfilesForGame(
        game,
        <String, AiProfile>{'victoria': victoria},
      );
      expect(resolved, isNotNull);
      expect(resolved!.keys, ['gp3']);
    });

    test('returns null when every slot is null/empty', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
        aiProfileByGpId: const {'gp1': null, 'gp2': ''},
      );
      expect(resolveAiProfilesForGame(game, seedAiProfilesById), isNull);
    });
  });

  group('encode/decode isolate profiles', () {
    test('round-trips profile map', () {
      final victoria = seedAiProfilesById['victoria']!;
      final encoded = encodeAiProfilesForIsolate(<String, AiProfile>{
        'gp2': victoria,
      });
      final decoded = decodeAiProfilesFromIsolate(encoded);
      expect(decoded, isNotNull);
      expect(decoded!['gp2']!.profileId, victoria.profileId);
    });

    test('encode returns empty for null or empty input', () {
      expect(encodeAiProfilesForIsolate(null), isEmpty);
      expect(encodeAiProfilesForIsolate(const {}), isEmpty);
    });

    test('decode returns null for non-map or empty payloads', () {
      expect(decodeAiProfilesFromIsolate(null), isNull);
      expect(decodeAiProfilesFromIsolate('not-a-map'), isNull);
      expect(decodeAiProfilesFromIsolate(<Object?, Object?>{}), isNull);
    });

    test('decode skips entries with non-map values', () {
      final victoria = seedAiProfilesById['victoria']!;
      final payload = <Object?, Object?>{
        'gp1': 'not-a-profile-map',
        'gp2': victoria.toJson(),
      };
      final decoded = decodeAiProfilesFromIsolate(payload);
      expect(decoded, isNotNull);
      expect(decoded!.keys, ['gp2']);
    });

    test('decode returns null when no entries are valid', () {
      final payload = <Object?, Object?>{'gp1': 'x', 'gp2': 7};
      expect(decodeAiProfilesFromIsolate(payload), isNull);
    });
  });
}
