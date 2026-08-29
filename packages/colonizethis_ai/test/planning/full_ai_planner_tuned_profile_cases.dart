// Case bodies for `full_ai_planner_test.dart` tuned-profile integration pins (Refs #3444).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/full_ai_planner_test_support.dart';

void registerFullAiPlannerTunedProfileCases() {
  group('tuned AI profile overrides reach the AI trace (Refs #3444)', () {
    Game aiGame() => fullAiPlannerMinimalGame(
      players: const [
        Player(
          id: 'gp1',
          displayName: 'England',
          isHuman: false,
          leaderKey: 'victoria',
        ),
      ],
      aiControlByGpId: const {'gp1': true},
      hiddenAgendaByGpId: const {'gp1': 'peacemaker'},
    );

    int expandWeightOf(TurnTraceAiSection section) {
      final constants = section.thresholds['constants'] as Map<String, Object?>;
      final goalWeights = constants['goalWeights'] as Map<String, Object?>;
      return goalWeights['expand'] as int;
    }

    String? profileIdOf(TurnTraceAiSection section) {
      final context = section.state['decisionContext'] as Map<String, Object?>;
      return context['profileId'] as String?;
    }

    AiProfile tunedExpandProfile(String id, int expandWeight) =>
        AiProfile.fromJson(<String, dynamic>{
          'schema_version': kAiProfileSchemaVersion,
          'profile_id': id,
          'display_name': 'Tuned $id',
          'parameters': <String, num>{
            'personalityGoalWeights.expand': expandWeight,
          },
        });

    int observableExpandOverride(int baseExpand) {
      final registryDefault = AiParameterRegistry
          .defaults['personalityGoalWeights.expand']!
          .round();
      return const [
        3,
        7,
        11,
        23,
        47,
        71,
        97,
      ].firstWhere((v) => v != baseExpand && v != registryDefault);
    }

    test('overridden goal weight and profileId appear in the trace', () {
      const topology = MapTopology(nodes: [], edges: []);

      final baseline = generateOrdersForGameFullAI(
        aiGame(),
        topology,
      ).aiTraceSections.single;
      final baseExpand = expandWeightOf(baseline);
      expect(profileIdOf(baseline), isNull);

      final override = observableExpandOverride(baseExpand);
      final profile = tunedExpandProfile('tuned_expand', override);

      final tuned = generateOrdersForGameFullAI(
        aiGame(),
        topology,
        profiles: <String, AiProfile>{'gp1': profile},
      ).aiTraceSections.single;

      expect(profileIdOf(tuned), 'tuned_expand');
      expect(expandWeightOf(tuned), override);
      expect(expandWeightOf(tuned), isNot(baseExpand));
    });

    test('profile mapped to a different slot leaves this AI on normal '
        'weights', () {
      const topology = MapTopology(nodes: [], edges: []);

      final baseline = generateOrdersForGameFullAI(
        aiGame(),
        topology,
      ).aiTraceSections.single;
      final baseExpand = expandWeightOf(baseline);

      final override = observableExpandOverride(baseExpand);
      final profile = tunedExpandProfile('tuned_expand', override);

      final tuned = generateOrdersForGameFullAI(
        aiGame(),
        topology,
        profiles: <String, AiProfile>{'gp2': profile},
      ).aiTraceSections.single;

      expect(profileIdOf(tuned), isNull);
      expect(expandWeightOf(tuned), baseExpand);
    });
  });
}
