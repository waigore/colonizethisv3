import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_domain_package_source_file_size.dart';

void main() {
  test('passes for the real post-split domain-package source trees', () {
    final logs = <String>[];
    final code = runCheckDomainPackageSourceFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'All eight domain packages must stay at or below '
          '${maxDomainPackageSourceFilePhysicalLinesForTests()} physical lines '
          'per lib/src file.\n${logs.join('\n')}',
    );
  });

  test('fails when a domain-package source file exceeds 500 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_domain_package_source_file_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final domain in domainPackageSourceFileSizeDomainsForTests) {
      Directory(
        '${temp.path}/packages/colonizethis_$domain/lib/src',
      ).createSync(recursive: true);
    }

    final violatingFile = File(
      '${temp.path}/packages/colonizethis_world/lib/src/huge.dart',
    )..createSync(recursive: true);
    violatingFile.writeAsStringSync(List.filled(501, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckDomainPackageSourceFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge.dart'));
    expect(logs.join('\n'), contains('501 physical lines > 500'));
  });

  test('ignores generated files over 500 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_domain_package_source_file_size_generated_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final domain in domainPackageSourceFileSizeDomainsForTests) {
      Directory(
        '${temp.path}/packages/colonizethis_$domain/lib/src',
      ).createSync(recursive: true);
    }

    final generatedFile = File(
      '${temp.path}/packages/colonizethis_world/lib/src/huge.g.dart',
    )..createSync(recursive: true);
    generatedFile.writeAsStringSync(List.filled(501, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckDomainPackageSourceFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0, reason: logs.join('\n'));
  });

  test('fails when a domain-package lib/src directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_domain_package_source_file_size_no_dir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckDomainPackageSourceFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('lib/src not found'));
  });

  test('only checks provided target files when target list is set', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_domain_package_source_file_size_targets_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final domain in domainPackageSourceFileSizeDomainsForTests) {
      Directory(
        '${temp.path}/packages/colonizethis_$domain/lib/src',
      ).createSync(recursive: true);
    }

    final largeUntargeted = File(
      '${temp.path}/packages/colonizethis_world/lib/src/large_untargeted.dart',
    )..createSync(recursive: true);
    largeUntargeted.writeAsStringSync(List.filled(501, '// line').join('\n'));

    final smallTargeted = File(
      '${temp.path}/packages/colonizethis_orders/lib/src/small_targeted.dart',
    )..createSync(recursive: true);
    smallTargeted.writeAsStringSync(List.filled(10, '// line').join('\n'));

    final code = runCheckDomainPackageSourceFileSize(
      temp.path,
      targetFiles: const [
        'packages/colonizethis_orders/lib/src/small_targeted.dart',
      ],
    );

    expect(code, 0);
  });
}
