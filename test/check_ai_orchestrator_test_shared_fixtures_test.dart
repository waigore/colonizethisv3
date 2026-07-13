import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_orchestrator_test_shared_fixtures.dart';

const String _localBelowQuotaBody =
    "import 'package:test/test.dart';\n\n"
    'const List<String> _gp1OwProvincesBelowQuota = <String>[\n'
    "  'oldWorld|gp1_0',\n"
    "  'oldWorld|gp1_1',\n"
    '];\n\n'
    'void main() {}\n';

const String _localAtQuotaBody =
    "import 'package:test/test.dart';\n\n"
    'const List<String> _gp1OwProvincesAtQuota = <String>[\n'
    "  'oldWorld|gp1_0',\n"
    "  'oldWorld|gp1_1',\n"
    "  'oldWorld|gp1_2',\n"
    "  'oldWorld|gp1_3',\n"
    "  'oldWorld|gp1_4',\n"
    "  'oldWorld|gp1_5',\n"
    "  'oldWorld|gp1_6',\n"
    "  'oldWorld|gp1_7',\n"
    "  'oldWorld|gp1_8',\n"
    "  'oldWorld|gp1_9',\n"
    "  'oldWorld|gp1_10',\n"
    '];\n\n'
    'void main() {}\n';

const String _localBareGp1Body =
    "import 'package:test/test.dart';\n\n"
    'const List<String> _gp1OwProvinces = <String>[\n'
    "  'oldWorld|gp1_0',\n"
    "  'oldWorld|gp1_1',\n"
    '];\n\n'
    'void main() {}\n';

const String _localExpandTwoGpBody =
    "import 'package:test/test.dart';\n\n"
    'const List<String> _gp1Provinces = <String>[\n'
    "  'oldWorld|gp1_0',\n"
    "  'oldWorld|gp1_1',\n"
    '];\n\n'
    'void main() {}\n';

const String _sharedImportBody =
    "import 'package:test/test.dart';\n"
    "import '../support/domain_planner_orchestrator_test_support.dart';\n\n"
    'void main() {\n'
    '  expect(kGp1OwProvincesBelowQuota, isNotEmpty);\n'
    '  expect(kGp1OwProvincesAtQuota, isNotEmpty);\n'
    '  expect(kGp1OwProvincesExpandTwoGp, isNotEmpty);\n'
    '}\n';

void main() {
  group('runCheckAiOrchestratorTestSharedFixtures', () {
    test('fails when an orchestrator pin redeclares below-quota OW list', () {
      final temp = Directory.systemTemp.createTempSync('ai-orch-below-');
      try {
        _writeSupportStub(temp);
        _writeOrchestratorTest(temp, 'below_quota_test.dart', _localBelowQuotaBody);

        final errors = <String>[];
        final exitCode = runCheckAiOrchestratorTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_gp1OwProvincesBelowQuota'));
        expect(errors.join('\n'), contains('kGp1OwProvincesBelowQuota'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when an orchestrator pin redeclares at-quota OW list', () {
      final temp = Directory.systemTemp.createTempSync('ai-orch-at-');
      try {
        _writeSupportStub(temp);
        _writeOrchestratorTest(temp, 'at_quota_test.dart', _localAtQuotaBody);

        final errors = <String>[];
        final exitCode = runCheckAiOrchestratorTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_gp1OwProvincesAtQuota'));
        expect(errors.join('\n'), contains('kGp1OwProvincesAtQuota'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when an orchestrator pin redeclares bare _gp1OwProvinces', () {
      final temp = Directory.systemTemp.createTempSync('ai-orch-bare-');
      try {
        _writeSupportStub(temp);
        _writeOrchestratorTest(temp, 'bare_gp1_test.dart', _localBareGp1Body);

        final errors = <String>[];
        final exitCode = runCheckAiOrchestratorTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_gp1OwProvinces'));
        expect(errors.join('\n'), contains('kGp1OwProvincesAtQuota'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when an orchestrator pin redeclares _gp1Provinces', () {
      final temp = Directory.systemTemp.createTempSync('ai-orch-expand-');
      try {
        _writeSupportStub(temp);
        _writeOrchestratorTest(
          temp,
          'expand_two_gp_test.dart',
          _localExpandTwoGpBody,
        );

        final errors = <String>[];
        final exitCode = runCheckAiOrchestratorTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_gp1Provinces'));
        expect(errors.join('\n'), contains('kGp1OwProvincesExpandTwoGp'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when pins import the shared fixture constants', () {
      final temp = Directory.systemTemp.createTempSync('ai-orch-ok-');
      try {
        _writeSupportStub(temp);
        _writeOrchestratorTest(temp, 'shared_ok_test.dart', _sharedImportBody);

        final exitCode = runCheckAiOrchestratorTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when the shared support file is missing', () {
      final temp = Directory.systemTemp.createTempSync('ai-orch-missing-');
      try {
        final exitCode = runCheckAiOrchestratorTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
      'fails when a minor-war Game pin redeclares local _expandSnapshot',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-orch-snap-');
        try {
          _writeSupportStub(temp);
          _writeOrchestratorTest(
            temp,
            'expand_snap_clone_test.dart',
            "import 'package:test/test.dart';\n\n"
            'AIWorldSnapshot _expandSnapshot() {\n'
            '  return const AIWorldSnapshot(playerId: "gp1");\n'
            '}\n\n'
            'void main() {\n'
            '  buildOrchestratorExpandMinorWarScenarioGame(id: "g");\n'
            '}\n',
          );

          final errors = <String>[];
          final exitCode = runCheckAiOrchestratorTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('_expandSnapshot'));
          expect(
            errors.join('\n'),
            contains('buildOrchestratorExpandMinorWarAtWarSnapshot'),
          );
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'passes when a minor-war Game pin uses the shared at-war snapshot',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-orch-snap-ok-');
        try {
          _writeSupportStub(temp);
          _writeOrchestratorTest(
            temp,
            'expand_snap_shared_test.dart',
            "import 'package:test/test.dart';\n"
            "import '../support/domain_planner_orchestrator_test_support.dart';\n\n"
            'void main() {\n'
            '  buildOrchestratorExpandMinorWarScenarioGame(id: "g");\n'
            '  final snap = buildOrchestratorExpandMinorWarAtWarSnapshot();\n'
            '  expect(snap.playerId, isNotEmpty);\n'
            '}\n',
          );

          final exitCode = runCheckAiOrchestratorTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: (_) {},
          );
          expect(exitCode, 0);
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'fails when a tribe-NW Game pin redeclares local _colonialSnapshot',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-orch-tribe-');
        try {
          _writeSupportStub(temp);
          _writeOrchestratorTest(
            temp,
            'tribe_snap_clone_test.dart',
            "import 'package:test/test.dart';\n\n"
            'AIWorldSnapshot _colonialSnapshot() {\n'
            '  return const AIWorldSnapshot(playerId: "gp1");\n'
            '}\n\n'
            'void main() {\n'
            '  buildOrchestratorGp1TribeNwScenarioGame(\n'
            '    id: "g",\n'
            '    gp1OwProvinces: const <String>[],\n'
            '  );\n'
            '}\n',
          );

          final errors = <String>[];
          final exitCode = runCheckAiOrchestratorTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('_colonialSnapshot'));
          expect(
            errors.join('\n'),
            contains('buildOrchestratorColonialNwTribeTargetSnapshot'),
          );
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'fails when a GP-blocker Game pin redeclares local _developSnapshot',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-orch-gpblock-');
        try {
          _writeSupportStub(temp);
          _writeOrchestratorTest(
            temp,
            'gp_blocker_snap_clone_test.dart',
            "import 'package:test/test.dart';\n\n"
            'AIWorldSnapshot _developSnapshot() {\n'
            '  return const AIWorldSnapshot(playerId: "gp1");\n'
            '}\n\n'
            'void main() {\n'
            '  buildOrchestratorExpandGpOnlyBlockerScenarioGame(\n'
            '    id: "g",\n'
            '    gp1OwProvinces: const <String>[],\n'
            '  );\n'
            '}\n',
          );

          final errors = <String>[];
          final exitCode = runCheckAiOrchestratorTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('_developSnapshot'));
          expect(
            errors.join('\n'),
            contains('buildOrchestratorDevelopGpOnlyBlockerSnapshot'),
          );
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'fails when an adjacent-minor Game pin redeclares local _expandSnapshot',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-orch-adj-');
        try {
          _writeSupportStub(temp);
          _writeOrchestratorTest(
            temp,
            'adj_minor_snap_clone_test.dart',
            "import 'package:test/test.dart';\n\n"
            'AIWorldSnapshot _expandSnapshot() {\n'
            '  return const AIWorldSnapshot(playerId: "gp1");\n'
            '}\n\n'
            'void main() {\n'
            '  buildOrchestratorExpandAdjacentMinorScenarioGame(\n'
            '    id: "g",\n'
            '    gp1OwProvinces: const <String>[],\n'
            '  );\n'
            '}\n',
          );

          final errors = <String>[];
          final exitCode = runCheckAiOrchestratorTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('_expandSnapshot'));
          expect(
            errors.join('\n'),
            contains('buildOrchestratorExpandAdjacentMinorSnapshot'),
          );
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'fails when a DEVELOP GP-owned-NW Game pin redeclares _developSnapshot',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-orch-dev-');
        try {
          _writeSupportStub(temp);
          _writeOrchestratorTest(
            temp,
            'develop_snap_clone_test.dart',
            "import 'package:test/test.dart';\n\n"
            'AIWorldSnapshot _developSnapshot() {\n'
            '  return const AIWorldSnapshot(playerId: "gp1");\n'
            '}\n\n'
            'void main() {\n'
            '  buildOrchestratorDevelopGpOwnedNwScenarioGame(id: "g");\n'
            '}\n',
          );

          final errors = <String>[];
          final exitCode = runCheckAiOrchestratorTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('_developSnapshot'));
          expect(
            errors.join('\n'),
            contains('buildOrchestratorDevelopNoColonialTargetsSnapshot'),
          );
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'fails when a COLONIAL-lite declare-war Game pin redeclares '
      '_colonialLiteSnapshot',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-orch-clite-');
        try {
          _writeSupportStub(temp);
          _writeOrchestratorTest(
            temp,
            'colonial_lite_snap_clone_test.dart',
            "import 'package:test/test.dart';\n\n"
            'AIWorldSnapshot _colonialLiteSnapshot() {\n'
            '  return const AIWorldSnapshot(playerId: "gp1");\n'
            '}\n\n'
            'void main() {\n'
            '  buildOrchestratorColonialLiteDeclareWarScenarioGame(\n'
            '    id: "g",\n'
            '    gp1OwProvinces: const <String>[],\n'
            '  );\n'
            '}\n',
          );

          final errors = <String>[];
          final exitCode = runCheckAiOrchestratorTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('_colonialLiteSnapshot'));
          expect(
            errors.join('\n'),
            contains('buildOrchestratorExpandNwTribeTargetSnapshot'),
          );
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'fails when a diplomatic-scoring COLONIAL adopter redeclares '
      'brace-bodied _colonialSnapshot',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-orch-diplo-');
        try {
          _writeSupportStub(temp);
          _writeDiplomaticScoringAdopter(
            temp,
            'diplomatic_candidate_scoring_personality_colonial_divergence_test.dart',
            "import 'package:test/test.dart';\n\n"
            'AIWorldSnapshot _colonialSnapshot() {\n'
            '  return const AIWorldSnapshot(playerId: "gp1");\n'
            '}\n\n'
            'void main() {}\n',
          );

          final errors = <String>[];
          final exitCode = runCheckAiOrchestratorTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('_colonialSnapshot'));
          expect(
            errors.join('\n'),
            contains('buildOrchestratorColonialNwTribeTargetSnapshot'),
          );
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'fails when a diplomatic-scoring COLONIAL adopter redeclares '
      '_gp1OwProvincesAtQuota',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-orch-diplo-q-');
        try {
          _writeSupportStub(temp);
          _writeDiplomaticScoringAdopter(
            temp,
            'diplomatic_candidate_scoring_intervention_tribe_tolerance_test.dart',
            _localAtQuotaBody,
          );

          final errors = <String>[];
          final exitCode = runCheckAiOrchestratorTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('_gp1OwProvincesAtQuota'));
          expect(errors.join('\n'), contains('kGp1OwProvincesAtQuota'));
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );
  });
}

void _writeSupportStub(Directory temp) {
  final support = Directory(
    p.join(
      temp.path,
      'packages',
      'colonizethis_ai',
      'test',
      'support',
    ),
  )..createSync(recursive: true);
  File(
    p.join(support.path, 'domain_planner_orchestrator_test_support.dart'),
  ).writeAsStringSync(
    "const List<String> kGp1OwProvincesBelowQuota = <String>['a'];\n"
    "const List<String> kGp1OwProvincesAtQuota = <String>['b'];\n"
    "const List<String> kGp1OwProvincesExpandTwoGp = <String>['c'];\n",
  );
}

void _writeOrchestratorTest(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(
      temp.path,
      'packages',
      'colonizethis_ai',
      'test',
      'planning',
    ),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'domain_planner_orchestrator_$name'),
  ).writeAsStringSync(body);
}

void _writeDiplomaticScoringAdopter(
  Directory temp,
  String basename,
  String body,
) {
  final planning = Directory(
    p.join(
      temp.path,
      'packages',
      'colonizethis_ai',
      'test',
      'planning',
    ),
  )..createSync(recursive: true);
  File(p.join(planning.path, basename)).writeAsStringSync(body);
}
