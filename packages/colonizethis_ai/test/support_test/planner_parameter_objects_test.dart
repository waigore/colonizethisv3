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
        contains(
          'TurnTraceAiSection buildAiTraceSection(AiTraceBuildInput input)',
        ),
      );

      final treasuryInput = File(
        p.join(planningDir.path, 'treasury_planner_input.dart'),
      ).readAsStringSync();
      expect(treasuryInput, contains('final class TreasuryPlannerInput'));

      final treasury = File(
        p.join(planningDir.path, 'treasury_planner.dart'),
      ).readAsStringSync();
      expect(
        treasury,
        contains(
          'List<TradeOrder> runTreasuryPlanner(TreasuryPlannerInput input)',
        ),
      );

      final recruitmentTypes = File(
        p.join(planningDir.path, 'recruitment_planner_types.dart'),
      ).readAsStringSync();
      expect(recruitmentTypes, contains('final class RecruitmentPlannerInput'));

      final recruitment = File(
        p.join(planningDir.path, 'recruitment_planner.dart'),
      ).readAsStringSync();
      expect(
        recruitment,
        contains(
          'RecruitmentPlan runRecruitmentPlanner(RecruitmentPlannerInput input)',
        ),
      );
    });

    test('recruitment planner is concern-split into explicit-import libraries '
        '(Refs #3997 AC5; #4079 Slice A)', () {
      final recruitment = File(
        p.join(planningDir.path, 'recruitment_planner.dart'),
      );
      final candidates = File(
        p.join(planningDir.path, 'recruitment_planner_candidates.dart'),
      );
      final types = File(
        p.join(planningDir.path, 'recruitment_planner_types.dart'),
      );
      expect(candidates.existsSync(), isTrue);
      expect(types.existsSync(), isTrue);

      final recruitmentSource = recruitment.readAsStringSync();
      final candidatesSource = candidates.readAsStringSync();
      final typesSource = types.readAsStringSync();
      for (final source in [recruitmentSource, candidatesSource, typesSource]) {
        expect(source, isNot(contains("part '")));
        expect(source, isNot(contains('part of ')));
      }
      expect(
        recruitmentSource,
        contains("import 'recruitment_planner_candidates.dart';"),
      );
      expect(
        recruitmentSource,
        contains("import 'recruitment_planner_types.dart';"),
      );
      expect(
        candidatesSource,
        contains("import 'recruitment_planner_types.dart';"),
      );
      expect(
        recruitment.readAsLinesSync().length,
        lessThanOrEqualTo(250),
        reason:
            'recruitment_planner.dart keeps the public surface + thin '
            'orchestrator after candidate concern split',
      );
      // Positive: entry body stays comfortably under the ~200-line extract
      // threshold (gather/evaluate/emit live in the candidates part).
      final lines = recruitment.readAsLinesSync();
      final start = lines.indexWhere(
        (l) => l.contains(
          'RecruitmentPlan runRecruitmentPlanner(RecruitmentPlannerInput input)',
        ),
      );
      expect(start, greaterThanOrEqualTo(0));
      var depth = 0;
      var started = false;
      var end = start;
      for (var i = start; i < lines.length; i++) {
        depth +=
            '{'.allMatches(lines[i]).length - '}'.allMatches(lines[i]).length;
        if (lines[i].contains('{')) started = true;
        if (started && depth == 0) {
          end = i;
          break;
        }
      }
      final bodyLines = end - start + 1;
      expect(
        bodyLines,
        lessThanOrEqualTo(80),
        reason:
            'runRecruitmentPlanner body should stay well under ~200 after '
            'concern split (was 199); got $bodyLines',
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

    test('economy labour helpers are topic-split into an explicit-import '
        'library (Refs #4079 Slice A)', () {
      final economy = File(p.join(planningDir.path, 'economy_planner.dart'));
      final labour = File(
        p.join(planningDir.path, 'economy_planner_labour.dart'),
      );
      expect(labour.existsSync(), isTrue);

      final economySource = economy.readAsStringSync();
      final labourSource = labour.readAsStringSync();
      for (final source in [economySource, labourSource]) {
        expect(source, isNot(contains("part '")));
        expect(source, isNot(contains('part of ')));
      }
      expect(economySource, contains("import 'economy_planner_labour.dart';"));
      expect(
        labourSource,
        contains("import 'economy_planner_labour_input.dart';"),
      );
      expect(
        File(
          p.join(planningDir.path, 'economy_planner_labour_input.dart'),
        ).existsSync(),
        isTrue,
      );
      expect(
        economy.readAsLinesSync().length,
        lessThanOrEqualTo(750),
        reason: 'economy_planner.dart should sit under ~750 after labour split',
      );
    });

    test('near-gate colonial/diplomacy/orchestrator files are topic-split', () {
      final colonial = File(
        p.join(planningDir.path, 'colonial_phase_planner.dart'),
      ).readAsStringSync();
      // Slice A (#4365): colonial barrel is a thin re-export host.
      expect(colonial, contains("export 'colonial_phase_planner_naval.dart';"));
      expect(colonial, contains("export 'colonial_phase_planner_lite.dart';"));
      expect(
        colonial,
        contains("export 'colonial_phase_planner_civilian.dart';"),
      );
      expect(colonial, isNot(contains("part '")));

      for (final name in <String>[
        'colonial_phase_planner_naval.dart',
        'colonial_phase_planner_lite.dart',
        'colonial_phase_planner_civilian.dart',
        'diplomacy_planner.dart',
        'diplomacy_planner_pass_helpers.dart',
        'domain_planner_orchestrator_economy.dart',
        'domain_planner_orchestrator_economy_build.dart',
      ]) {
        final file = File(p.join(planningDir.path, name));
        expect(file.existsSync(), isTrue, reason: name);
        expect(
          file.readAsLinesSync().length,
          lessThanOrEqualTo(750),
          reason: '$name should sit under ~750 after Phase-5 near-gate splits',
        );
        expect(
          file.readAsStringSync(),
          isNot(contains("part of '")),
          reason: '$name should be an explicit-import library (Refs #4079)',
        );
      }

      final diplomacy = File(
        p.join(planningDir.path, 'diplomacy_planner.dart'),
      ).readAsStringSync();
      // Slice A (#4365): diplomacy barrel re-exports run; helpers stay in run.
      expect(diplomacy, contains("export 'diplomacy_planner_run.dart'"));
      expect(diplomacy, isNot(contains("part '")));
      final diplomacyRun = File(
        p.join(planningDir.path, 'diplomacy_planner_run.dart'),
      ).readAsStringSync();
      expect(
        diplomacyRun,
        contains("import 'diplomacy_planner_pass_helpers.dart';"),
      );

      final orchestrator = File(
        p.join(planningDir.path, 'domain_planner_orchestrator.dart'),
      ).readAsStringSync();
      expect(
        orchestrator,
        contains("import 'domain_planner_orchestrator_economy.dart';"),
      );
      expect(orchestrator, isNot(contains("part '")));

      final economy = File(
        p.join(planningDir.path, 'domain_planner_orchestrator_economy.dart'),
      ).readAsStringSync();
      expect(
        economy,
        contains("import 'domain_planner_orchestrator_economy_build.dart';"),
      );
    });

    test(
      'negative: colonial naval monolith must not reabsorb lite/civilian',
      () {
        final naval = File(
          p.join(planningDir.path, 'colonial_phase_planner_naval.dart'),
        ).readAsStringSync();
        expect(
          naval,
          isNot(contains('List<String> planColonialLiteOvertures')),
        );
        expect(naval, isNot(contains('List<WorkOrder> planColonialCivilian')));
        expect(naval, isNot(contains('final class ColonialLiteNavalPlan')));
        expect(
          naval,
          isNot(contains('ColonialLiteNavalPlan planColonialLiteNaval')),
        );
      },
    );
  });
}
