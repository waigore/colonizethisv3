import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_shell_panel_dedup.dart';

void main() {
  group('runCheckAppShellPanelDedup', () {
    test('fails for a direct shellPanelsNotDefined call in a screen', () {
      final temp = Directory.systemTemp.createTempSync(
        'shell-panel-dedup-bad-',
      );
      try {
        // Allowlisted helper keeps the canonical call so the symbol is "used".
        _writeDartFile(
          p.join(temp.path, shellPanelDedupHelperPath),
          "Widget? observeNotDefinedSentinel(shell, title) {\n"
          "  if (shellPanelsNotDefined(shell)) return Panel();\n"
          "  return null;\n}\n",
        );
        _writeDartFile(
          p.join(
            temp.path,
            'app',
            'lib',
            'features',
            'game',
            'screens',
            'trade_screen.dart',
          ),
          "Widget build(context) {\n"
          "  if (shellPanelsNotDefined(shell)) return Panel();\n"
          "  return Body();\n}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAppShellPanelDedup(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('trade_screen.dart:2'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when only the canonical helper calls the guard', () {
      final temp = Directory.systemTemp.createTempSync('shell-panel-dedup-ok-');
      try {
        _writeDartFile(
          p.join(temp.path, shellPanelDedupHelperPath),
          "Widget? observeNotDefinedSentinel(shell, title) {\n"
          "  if (shellPanelsNotDefined(shell)) return Panel();\n"
          "  return null;\n}\n",
        );
        _writeDartFile(
          p.join(
            temp.path,
            'app',
            'lib',
            'features',
            'game',
            'screens',
            'trade_screen.dart',
          ),
          "Widget build(context) {\n"
          "  final s = observeNotDefinedSentinel(shell, 'Trade');\n"
          "  if (s != null) return s;\n"
          "  return Body();\n}\n",
        );

        final exitCode = runCheckAppShellPanelDedup(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when only the declaration site references the guard', () {
      final temp = Directory.systemTemp.createTempSync(
        'shell-panel-dedup-def-',
      );
      try {
        _writeDartFile(
          p.join(temp.path, shellPanelDedupDefinitionPath),
          "bool shellPanelsNotDefined(ShellPlayerContext shell) =>\n"
          "    !shell.showPlayerChrome;\n",
        );

        final exitCode = runCheckAppShellPanelDedup(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores a commented-out reference to the guard', () {
      final temp = Directory.systemTemp.createTempSync(
        'shell-panel-dedup-comment-',
      );
      try {
        _writeDartFile(
          p.join(
            temp.path,
            'app',
            'lib',
            'features',
            'game',
            'screens',
            'production_screen.dart',
          ),
          "Widget build(context) {\n"
          "  /// See shellPanelsNotDefined(shell) for the observe-mode guard.\n"
          "  // shellPanelsNotDefined(shell) is wrapped by the helper now.\n"
          "  return Body();\n}\n",
        );

        final exitCode = runCheckAppShellPanelDedup(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores calls outside app/lib', () {
      final temp = Directory.systemTemp.createTempSync(
        'shell-panel-dedup-other-',
      );
      try {
        _writeDartFile(
          p.join(temp.path, 'packages', 'x', 'lib', 'src', 'thing.dart'),
          "void f() { shellPanelsNotDefined(shell); }\n",
        );

        final exitCode = runCheckAppShellPanelDedup(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('appShellPanelDedupPathInScope', () {
    test('excludes the allowlisted declaration and helper files', () {
      expect(
        appShellPanelDedupPathInScope(shellPanelDedupDefinitionPath),
        isFalse,
      );
      expect(appShellPanelDedupPathInScope(shellPanelDedupHelperPath), isFalse);
    });

    test('includes other app/lib files', () {
      expect(
        appShellPanelDedupPathInScope(
          'app/lib/features/game/screens/trade_screen.dart',
        ),
        isTrue,
      );
    });

    test('excludes non-app/lib paths', () {
      expect(
        appShellPanelDedupPathInScope('packages/x/lib/src/thing.dart'),
        isFalse,
      );
      expect(appShellPanelDedupPathInScope('app/test/foo_test.dart'), isFalse);
    });
  });

  group('appShellPanelDedupViolationLineNumbers', () {
    test('reports call lines and skips comments', () {
      const content =
          "// shellPanelsNotDefined(a)\n"
          "/// shellPanelsNotDefined(b)\n"
          "if (shellPanelsNotDefined(shell)) {}\n"
          "final shellPanelsNotDefinedFlag = true;\n"
          "x = shellPanelsNotDefined ( shell );\n";
      expect(appShellPanelDedupViolationLineNumbers(content), <int>[3, 5]);
    });

    test('does not match an identifier that merely starts with the name', () {
      expect(
        appShellPanelDedupViolationLineNumbers(
          'final shellPanelsNotDefinedCount = 0;\n',
        ),
        isEmpty,
      );
    });
  });
}

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
