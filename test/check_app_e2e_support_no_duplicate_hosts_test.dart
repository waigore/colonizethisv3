import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_e2e_support_no_duplicate_hosts.dart';

void main() {
  group('runCheckAppE2eSupportNoDuplicateHosts', () {
    test('fails when a pin suite re-declares _wrap', () {
      final temp = Directory.systemTemp.createTempSync(
        'e2e-support-no-dup-hosts-',
      );
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_app_e2e_support', 'test'),
        )..createSync(recursive: true);
        File(p.join(testDir.path, 'clone_wrap_test.dart')).writeAsStringSync(
          "import 'package:flutter/material.dart';\n"
          'Widget _wrap(Widget body) => MaterialApp(home: body);\n',
        );

        final errors = <String>[];
        final code = runCheckAppE2eSupportNoDuplicateHosts(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('clone_wrap_test.dart'));
        expect(errors.join('\n'), contains('_wrap'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when a pin suite constructs MaterialApp inline', () {
      final temp = Directory.systemTemp.createTempSync(
        'e2e-support-no-dup-hosts-app-',
      );
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_app_e2e_support', 'test'),
        )..createSync(recursive: true);
        File(p.join(testDir.path, 'clone_app_test.dart')).writeAsStringSync(
          "import 'package:flutter/material.dart';\n"
          "void main() {\n"
          "  final _ = MaterialApp(home: const SizedBox());\n"
          "}\n",
        );

        final errors = <String>[];
        final code = runCheckAppE2eSupportNoDuplicateHosts(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('clone_app_test.dart'));
        expect(errors.join('\n'), contains('MaterialApp'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('allows wrap hosts under test/support/', () {
      final temp = Directory.systemTemp.createTempSync(
        'e2e-support-dup-hosts-ok-',
      );
      try {
        final support = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_app_e2e_support',
            'test',
            'support',
          ),
        )..createSync(recursive: true);
        Directory(
          p.join(temp.path, 'packages', 'colonizethis_app_e2e_support', 'test'),
        ).createSync(recursive: true);
        File(
          p.join(support.path, 'e2e_widget_pump_harness.dart'),
        ).writeAsStringSync(
          "import 'package:flutter/material.dart';\n"
          'Widget _wrap(Widget body) => MaterialApp(home: body);\n',
        );
        File(
          p.join(
            temp.path,
            'packages',
            'colonizethis_app_e2e_support',
            'test',
            'ok_pin_test.dart',
          ),
        ).writeAsStringSync('void main() {}\n');

        final errors = <String>[];
        final code = runCheckAppE2eSupportNoDuplicateHosts(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 0, reason: errors.join('\n'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes on the real e2e_support pin tree', () {
      final logs = <String>[];
      final code = runCheckAppE2eSupportNoDuplicateHosts(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
