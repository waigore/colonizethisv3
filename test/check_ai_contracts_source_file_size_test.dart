import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_contracts_source_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

String _nLines(int count) =>
    List.generate(count, (i) => '// line $i').join('\n');

void main() {
  group('runCheckAiContractsSourceFileSize', () {
    test('passes on current repo tree under 250 physical-line ceiling', () {
      expect(runCheckAiContractsSourceFileSize('.'), 0);
    });

    test('ceiling is 250 after #4683 Slice D', () {
      expect(aiContractsSourceFileSizeCeiling, 250);
    });

    test('grandfather allowlist is empty', () {
      expect(aiContractsSourceFileSizeGrandfatheredForTests, isEmpty);
    });

    test('fails when a lib file has 251 physical lines', () {
      final root = Directory.systemTemp.createTempSync(
        'ai_contracts_src_size_251',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_ai_contracts/lib/src/ai/fat.dart',
        _nLines(251),
      );

      final errors = <String>[];
      final code = runCheckAiContractsSourceFileSize(
        root.path,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('fails when the scan root is missing', () {
      final root = Directory.systemTemp.createTempSync(
        'ai_contracts_src_size_missing',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final errors = <String>[];
      final code = runCheckAiContractsSourceFileSize(
        root.path,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('not found'));
    });
  });
}
