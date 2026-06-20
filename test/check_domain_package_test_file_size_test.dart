import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_domain_package_test_file_size.dart';

void main() {
  test('passes for the real post-split domain-package test trees', () {
    final logs = <String>[];
    final code = runCheckDomainPackageTestFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'All eight domain packages must stay at or below '
          '${maxDomainPackageTestFilePhysicalLinesForTests()} physical lines '
          'per test file.\n${logs.join('\n')}',
    );
  });

  test('fails when a domain-package test file exceeds 400 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_domain_package_test_file_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final domain in domainPackageTestFileSizeDomainsForTests) {
      Directory(
        '${temp.path}/packages/colonizethis_$domain/test',
      ).createSync(recursive: true);
    }

    final violatingFile = File(
      '${temp.path}/packages/colonizethis_world/test/huge_test.dart',
    )..createSync(recursive: true);
    violatingFile.writeAsStringSync(List.filled(401, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckDomainPackageTestFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge_test.dart'));
    expect(logs.join('\n'), contains('401 physical lines > 400'));
  });

  test('fails when a domain-package test directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_domain_package_test_file_size_no_dir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckDomainPackageTestFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('test not found'));
  });

  test('only checks provided target files when target list is set', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_domain_package_test_file_size_targets_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final domain in domainPackageTestFileSizeDomainsForTests) {
      Directory(
        '${temp.path}/packages/colonizethis_$domain/test',
      ).createSync(recursive: true);
    }

    final largeUntargeted = File(
      '${temp.path}/packages/colonizethis_world/test/large_untargeted_test.dart',
    )..createSync(recursive: true);
    largeUntargeted.writeAsStringSync(List.filled(401, '// line').join('\n'));

    final smallTargeted = File(
      '${temp.path}/packages/colonizethis_orders/test/small_targeted_test.dart',
    )..createSync(recursive: true);
    smallTargeted.writeAsStringSync(List.filled(10, '// line').join('\n'));

    final code = runCheckDomainPackageTestFileSize(
      temp.path,
      targetFiles: const [
        'packages/colonizethis_orders/test/small_targeted_test.dart',
      ],
    );

    expect(code, 0);
  });
}
