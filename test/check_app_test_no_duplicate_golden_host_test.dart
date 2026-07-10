import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_golden_host.dart';

const _kConsolidatedGolden = '''
import 'support/golden_capture_harness.dart';

void main() {
  testWidgets('golden uses harness', (tester) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: const ValueKey('k'),
      physicalSize: const Size(100, 100),
      child: const Placeholder(),
    );
  });
}
''';

const _kReintroducedPhysicalSize = '''
void main() {
  testWidgets('golden', (tester) async {
    tester.view.physicalSize = const Size(100, 100);
  });
}
''';

const _kReintroducedPumpBuilt = '''
Future<void> _pumpBuilt(WidgetTester tester) async {
  await tester.pump();
}

void main() {}
''';

void _writeGovernedFile(Directory temp, String name, String contents) {
  File('${temp.path}/app/test/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  test('passes when golden file uses shared harness', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_golden_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'sample_goldens_test.dart', _kConsolidatedGolden);

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateGoldenHost(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0);
    expect(logs.join('\n'), contains('no duplicated golden-host'));
  });

  test('fails when physicalSize is assigned outside support', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_golden_phys_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'sample_goldens_test.dart',
      _kReintroducedPhysicalSize,
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateGoldenHost(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('physicalSize'));
  });

  test('fails when _pumpBuilt is reintroduced in a golden file', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_golden_pump_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'sample_golden_test.dart',
      _kReintroducedPumpBuilt,
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateGoldenHost(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('_pumpBuilt'));
  });
}
