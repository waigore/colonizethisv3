/// Pins Phase-5 parameter-object extraction for planner entry points
/// (Refs #3972 AC5).
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  final packageRoot = Directory.current.path;
  final planningDir = Directory(p.join(packageRoot, 'lib', 'src', 'planning'));

  group('planner parameter objects (Refs #3972 AC5)', () {
    test('public entries accept a single input object', () {
      final aiTrace = File(
        p.join(planningDir.path, 'ai_trace_builder.dart'),
      ).readAsStringSync();
      expect(aiTrace, contains('final class AiTraceBuildInput'));
      expect(
        aiTrace,
        contains('TurnTraceAiSection buildAiTraceSection(AiTraceBuildInput input)'),
      );

      final treasury = File(
        p.join(planningDir.path, 'treasury_planner.dart'),
      ).readAsStringSync();
      expect(treasury, contains('final class TreasuryPlannerInput'));
      expect(
        treasury,
        contains('List<TradeOrder> runTreasuryPlanner(TreasuryPlannerInput input)'),
      );

      final recruitment = File(
        p.join(planningDir.path, 'recruitment_planner.dart'),
      ).readAsStringSync();
      expect(recruitment, contains('final class RecruitmentPlannerInput'));
      expect(
        recruitment,
        contains(
          'RecruitmentPlan runRecruitmentPlanner(RecruitmentPlannerInput input)',
        ),
      );
    });

    test('negative: flat ≥8-param public signatures are gone', () {
      final aiTrace = File(
        p.join(planningDir.path, 'ai_trace_builder.dart'),
      ).readAsStringSync();
      expect(aiTrace, isNot(contains('buildAiTraceSection({')));

      final treasury = File(
        p.join(planningDir.path, 'treasury_planner.dart'),
      ).readAsStringSync();
      expect(treasury, isNot(contains('runTreasuryPlanner({')));

      final recruitment = File(
        p.join(planningDir.path, 'recruitment_planner.dart'),
      ).readAsStringSync();
      expect(recruitment, isNot(contains('runRecruitmentPlanner({')));
    });

    test('economy labour helpers are topic-split under the near-gate preference',
        () {
      final economy = File(
        p.join(planningDir.path, 'economy_planner.dart'),
      );
      final labour = File(
        p.join(planningDir.path, 'economy_planner_labour.dart'),
      );
      expect(labour.existsSync(), isTrue);
      expect(
        economy.readAsStringSync(),
        contains("part 'economy_planner_labour.dart';"),
      );
      expect(
        labour.readAsStringSync(),
        contains("part of 'economy_planner.dart';"),
      );
      expect(
        economy.readAsLinesSync().length,
        lessThanOrEqualTo(750),
        reason: 'economy_planner.dart should sit under ~750 after labour split',
      );
    });
  });
}
