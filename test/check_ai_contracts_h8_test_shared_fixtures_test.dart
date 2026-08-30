import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_contracts_h8_test_shared_fixtures.dart';

void main() {
  group('runCheckAiContractsH8TestSharedFixtures', () {
    test('fails when seller pin redeclares _flaggedSellerGame', () {
      final temp = Directory.systemTemp.createTempSync(
        'ai-contracts-h8-seller-',
      );
      try {
        _writeSupportStubs(temp);
        _writeSellerTargetTest(
          temp,
          "import 'package:test/test.dart';\n\n"
          'Game _flaggedSellerGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n\n'
          'void main() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiContractsH8TestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_flaggedSellerGame'));
        expect(errors.join('\n'), contains('flaggedSellerGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when prospect pin redeclares _supplierGame', () {
      final temp = Directory.systemTemp.createTempSync(
        'ai-contracts-h8-supplier-',
      );
      try {
        _writeSupportStubs(temp);
        _writeProspectLocalizationTest(
          temp,
          "import 'package:test/test.dart';\n\n"
          'Game _supplierGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n\n'
          'void main() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiContractsH8TestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_supplierGame'));
        expect(errors.join('\n'), contains('supplierGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when below-quota pin redeclares _belowQuotaSellerGame', () {
      final temp = Directory.systemTemp.createTempSync(
        'ai-contracts-h8-below-quota-',
      );
      try {
        _writeSupportStubs(temp);
        _writeBelowQuotaImprovementInputTest(
          temp,
          "import 'package:test/test.dart';\n\n"
          'Game _belowQuotaSellerGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n\n'
          'void main() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiContractsH8TestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_belowQuotaSellerGame'));
        expect(errors.join('\n'), contains('h8_below_quota_zero_nw_seller_game'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters import shared builders', () {
      final temp = Directory.systemTemp.createTempSync('ai-contracts-h8-ok-');
      try {
        _writeSupportStubs(temp);
        _writeSellerTargetTest(
          temp,
          "import 'package:test/test.dart';\n"
          "import 'support/h8_flagged_seller_game.dart';\n\n"
          'void main() {\n'
          '  final game = flaggedSellerGame();\n'
          '  expect(game, isNotNull);\n'
          '}\n',
        );
        _writeProspectLocalizationTest(
          temp,
          "import 'package:test/test.dart';\n"
          "import 'support/h8_supplier_prospect_game.dart';\n\n"
          'void main() {\n'
          '  final game = supplierGame();\n'
          '  expect(game, isNotNull);\n'
          '}\n',
        );
        final exitCode = runCheckAiContractsH8TestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when a shared support file is missing', () {
      final temp = Directory.systemTemp.createTempSync(
        'ai-contracts-h8-missing-',
      );
      try {
        final exitCode = runCheckAiContractsH8TestSharedFixtures(
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

void _writeSupportStubs(Directory temp) {
  final support = Directory(
    p.join(
      temp.path,
      'packages',
      'colonizethis_ai_contracts',
      'test',
      'support',
    ),
  )..createSync(recursive: true);
  File(
    p.join(support.path, 'h8_flagged_seller_game.dart'),
  ).writeAsStringSync('Object flaggedSellerGame() => Object();\n');
  File(
    p.join(support.path, 'h8_supplier_prospect_game.dart'),
  ).writeAsStringSync('Object supplierGame() => Object();\n');
  File(
    p.join(support.path, 'h8_below_quota_zero_nw_seller_game.dart'),
  ).writeAsStringSync('Object belowQuotaActiveGateSellerGame() => Object();\n');
}

void _writeSellerTargetTest(Directory temp, String body) {
  final testDir = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai_contracts', 'test'),
  )..createSync(recursive: true);
  File(
    p.join(
      testDir.path,
      'full_ai_civilian_work_seller_feedstock_acquisition_target_test.dart',
    ),
  ).writeAsStringSync(body);
}

void _writeProspectLocalizationTest(Directory temp, String body) {
  final testDir = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai_contracts', 'test'),
  )..createSync(recursive: true);
  File(
    p.join(
      testDir.path,
      'full_ai_civilian_work_ow_feedstock_prospect_localization_test.dart',
    ),
  ).writeAsStringSync(body);
}

void _writeBelowQuotaImprovementInputTest(Directory temp, String body) {
  final testDir = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai_contracts', 'test'),
  )..createSync(recursive: true);
  File(
    p.join(
      testDir.path,
      'full_ai_civilian_work_seller_improvement_input_feedstock_extraction_test.dart',
    ),
  ).writeAsStringSync(body);
}
