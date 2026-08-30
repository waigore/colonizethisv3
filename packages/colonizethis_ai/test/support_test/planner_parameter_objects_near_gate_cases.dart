import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

void registerPlannerParameterObjectsNearGateCases(String planningDirPath) {
  final planningDir = Directory(planningDirPath);
    test('near-gate colonial/diplomacy/orchestrator files are topic-split', () {
      final colonial = File(
        p.join(planningDirPath, 'colonial_phase_planner.dart'),
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
        final file = File(p.join(planningDirPath, name));
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
        p.join(planningDirPath, 'diplomacy_planner.dart'),
      ).readAsStringSync();
      // Slice A (#4365): diplomacy barrel re-exports run; helpers stay in run.
      expect(diplomacy, contains("export 'diplomacy_planner_run.dart'"));
      expect(diplomacy, isNot(contains("part '")));
      final diplomacyRun = File(
        p.join(planningDirPath, 'diplomacy_planner_run.dart'),
      ).readAsStringSync();
      expect(
        diplomacyRun,
        contains("import 'diplomacy_planner_pass_helpers.dart';"),
      );

      final orchestrator = File(
        p.join(planningDirPath, 'domain_planner_orchestrator.dart'),
      ).readAsStringSync();
      expect(
        orchestrator,
        contains("import 'domain_planner_orchestrator_economy.dart';"),
      );
      expect(orchestrator, isNot(contains("part '")));

      final economy = File(
        p.join(planningDirPath, 'domain_planner_orchestrator_economy.dart'),
      ).readAsStringSync();
      expect(
        economy,
        contains("import 'domain_planner_orchestrator_economy_build.dart';"),
      );
    });

}
