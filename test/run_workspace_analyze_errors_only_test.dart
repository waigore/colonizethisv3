import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/run_workspace_analyze_errors_only.dart';

void main() {
  group('countAnalyzerErrorLines', () {
    test('counts lines starting with optional whitespace then error', () {
      const out = '''
  error • Missing required parameter • lib/a.dart:1:1 • missing_required
warning • Unused import • lib/b.dart:2:2 • unused_import
  error • Undefined name • test/c_test.dart:3:3 • undefined_identifier
''';
      expect(countAnalyzerErrorLines(out), 2);
    });

    test('ignores info and warning', () {
      const out = '''
   info • Use const • lib/a.dart:1:1 • prefer_const
warning • Dead code • lib/b.dart:2:2 • dead_code
''';
      expect(countAnalyzerErrorLines(out), 0);
    });

    test('does not count error substring inside path', () {
      const out = r'''
  info • See lib/error_handler.dart • lib/a.dart:1:1 • todo
''';
      expect(countAnalyzerErrorLines(out), 0);
    });
  });

  group('packageDeclaresFlutterSdk', () {
    test('true when dependencies.flutter.sdk is flutter', () {
      expect(
        packageDeclaresFlutterSdk('''
name: x
dependencies:
  flutter:
    sdk: flutter
'''),
        isTrue,
      );
    });

    test('false for pure Dart package', () {
      expect(
        packageDeclaresFlutterSdk('''
name: x
dependencies:
  yaml: any
'''),
        isFalse,
      );
    });

    test('false when flutter is not sdk dependency', () {
      expect(
        packageDeclaresFlutterSdk('''
name: x
dependencies:
  flutter:
    path: ../flutter_stub
'''),
        isFalse,
      );
    });
  });

  group('packageHasL10nConfig', () {
    test('true when l10n.yaml exists at package root', () {
      final dir = Directory.systemTemp.createTempSync('ct_l10n_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(p.join(dir.path, 'l10n.yaml')).writeAsStringSync('arb-dir: l10n\n');
      expect(packageHasL10nConfig(dir.path), isTrue);
    });

    test('false when l10n.yaml is absent', () {
      final dir = Directory.systemTemp.createTempSync('ct_no_l10n_');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(packageHasL10nConfig(dir.path), isFalse);
    });
  });

  group('workspacePackageIsHostRoot', () {
    test('true when paths normalize to same directory', () {
      expect(
        workspacePackageIsHostRoot('/repo', '/repo/'),
        isTrue,
      );
    });

    test('false for nested package', () {
      expect(
        workspacePackageIsHostRoot('/repo', '/repo/app'),
        isFalse,
      );
    });
  });
}
