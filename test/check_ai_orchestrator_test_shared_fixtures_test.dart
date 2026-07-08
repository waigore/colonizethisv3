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
