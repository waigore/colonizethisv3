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
  });
}
