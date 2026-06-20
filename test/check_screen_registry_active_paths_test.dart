import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_screen_registry_active_paths.dart';

void main() {
  group('extractDartPathFromCell', () {
    test('returns null for TBD / em-dash / empty cells', () {
      expect(extractDartPathFromCell('TBD'), isNull);
      expect(extractDartPathFromCell('—'), isNull);
      expect(extractDartPathFromCell(''), isNull);
      expect(extractDartPathFromCell('   '), isNull);
    });

    test('returns the path for a backticked app/lib/...dart value', () {
      expect(
        extractDartPathFromCell('`app/lib/features/game/widgets/foo.dart`'),
        'app/lib/features/game/widgets/foo.dart',
      );
    });

    test('returns null for paths outside app/lib or non-.dart values', () {
      expect(
        extractDartPathFromCell('`packages/whatever/lib/foo.dart`'),
        isNull,
      );
      expect(extractDartPathFromCell('`app/lib/features/foo.txt`'), isNull);
      expect(
        extractDartPathFromCell('app/lib/features/game/widgets/foo.dart'),
        isNull,
        reason: 'cells without backticks should be rejected',
      );
    });
  });

  group('parseScreenRegistryRows', () {
    test('extracts id, implementation cell, status, and line number', () {
      final markdown = '''
# UI Screen Registry

## Categories

| code | flow |
|------|------|
| `SHEL` | shell |

## Registry

Status: `draft` = ...; `active` = ...

| ID | Title | Spec | Implementation | Widgetbook | Status |
|----|-------|------|----------------|------------|--------|
| `SHEL10001` | Shell screen | [shell.md](shell.md) | `app/lib/features/shell/shell_screen.dart` | Shell Screen | active |
| `SHEL30001` | Game initializing | [init.md](init.md) | TBD | — | draft |
| `SHEL40001` | Pause menu panel | [pause.md](pause.md) | TBD | Pause Menu Panel | active |
''';

      final rows = parseScreenRegistryRows(markdown);
      expect(rows.length, 3);

      expect(rows[0].id, 'SHEL10001');
      expect(
        rows[0].implementationCell.trim(),
        '`app/lib/features/shell/shell_screen.dart`',
      );
      expect(rows[0].status, 'active');

      expect(rows[1].id, 'SHEL30001');
      expect(rows[1].implementationCell.trim(), 'TBD');
      expect(rows[1].status, 'draft');

      expect(rows[2].id, 'SHEL40001');
      expect(rows[2].implementationCell.trim(), 'TBD');
      expect(rows[2].status, 'active');
      expect(rows[2].lineNumber, greaterThan(rows[1].lineNumber));
    });

    test('ignores tables outside the ## Registry section', () {
      final markdown = '''
# Title

## Categories

| Code | Flow |
|------|------|
| `SHEL` | shell |

## Component specs

| Document | Widget |
|----------|--------|
| foo.md | Foo |
''';

      expect(parseScreenRegistryRows(markdown), isEmpty);
    });
  });

  group('runCheckScreenRegistryActivePaths', () {
    test('passes when every active row points to an existing app/lib file', () {
      final temp = Directory.systemTemp.createTempSync(
        'screen_registry_active_paths_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeFile(
        temp,
        'app/lib/features/shell/shell_screen.dart',
        'class ShellScreen {}\n',
      );
      _writeFile(
        temp,
        'app/lib/features/game/widgets/pause_menu_panel.dart',
        'class PauseMenuPanel {}\n',
      );

      _writeFile(temp, 'SPEC/ui/screen-registry.md', '''
# UI Screen Registry

## Registry

| ID | Title | Spec | Implementation | Widgetbook | Status |
|----|-------|------|----------------|------------|--------|
| `SHEL10001` | Shell screen | [shell.md](shell.md) | `app/lib/features/shell/shell_screen.dart` | Shell Screen | active |
| `SHEL30001` | Game initializing | [init.md](init.md) | TBD | — | draft |
| `SHEL40001` | Pause menu panel | [pause.md](pause.md) | `app/lib/features/game/widgets/pause_menu_panel.dart` | Pause Menu Panel | active |
''');

      final logs = <String>[];
      final code = runCheckScreenRegistryActivePaths(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(logs.join('\n'), contains('2 active row(s) resolve'));
    });

    test('fails when an active row has TBD in its Implementation cell', () {
      final temp = Directory.systemTemp.createTempSync(
        'screen_registry_active_paths_tbd_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeFile(
        temp,
        'app/lib/features/shell/shell_screen.dart',
        'class ShellScreen {}\n',
      );

      _writeFile(temp, 'SPEC/ui/screen-registry.md', '''
# UI Screen Registry

## Registry

| ID | Title | Spec | Implementation | Widgetbook | Status |
|----|-------|------|----------------|------------|--------|
| `SHEL10001` | Shell screen | [shell.md](shell.md) | `app/lib/features/shell/shell_screen.dart` | Shell Screen | active |
| `SHEL40001` | Pause menu panel | [pause.md](pause.md) | TBD | Pause Menu Panel | active |
''');

      final logs = <String>[];
      final code = runCheckScreenRegistryActivePaths(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      final out = logs.join('\n');
      expect(out, contains('SHEL40001'));
      expect(out, contains('not a valid'));
    });

    test('fails when an active row points to a missing file', () {
      final temp = Directory.systemTemp.createTempSync(
        'screen_registry_active_paths_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeFile(temp, 'SPEC/ui/screen-registry.md', '''
# UI Screen Registry

## Registry

| ID | Title | Spec | Implementation | Widgetbook | Status |
|----|-------|------|----------------|------------|--------|
| `SHEL10001` | Shell screen | [shell.md](shell.md) | `app/lib/features/shell/shell_screen.dart` | Shell Screen | active |
''');

      final logs = <String>[];
      final code = runCheckScreenRegistryActivePaths(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      final out = logs.join('\n');
      expect(out, contains('SHEL10001'));
      expect(out, contains('does not exist on disk'));
    });

    test('does not flag draft rows with TBD or — cells', () {
      final temp = Directory.systemTemp.createTempSync(
        'screen_registry_active_paths_draft_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeFile(
        temp,
        'app/lib/features/shell/shell_screen.dart',
        'class ShellScreen {}\n',
      );

      _writeFile(temp, 'SPEC/ui/screen-registry.md', '''
# UI Screen Registry

## Registry

| ID | Title | Spec | Implementation | Widgetbook | Status |
|----|-------|------|----------------|------------|--------|
| `SHEL10001` | Shell screen | [shell.md](shell.md) | `app/lib/features/shell/shell_screen.dart` | Shell Screen | active |
| `DRAFT00001` | Reserved | [draft.md](draft.md) | TBD | — | draft |
| `DRAFT00002` | Reserved | [draft2.md](draft2.md) | — | — | draft |
''');

      final logs = <String>[];
      final code = runCheckScreenRegistryActivePaths(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('passes on the real repo registry (live regression)', () {
      final code = runCheckScreenRegistryActivePaths(Directory.current.path);
      expect(
        code,
        0,
        reason:
            'SPEC/ui/screen-registry.md must keep every active row pointing '
            'to an existing app/lib/...dart file on disk.',
      );
    });
  });
}

void _writeFile(Directory root, String relative, String contents) {
  final f = File(p.join(root.path, relative));
  f.createSync(recursive: true);
  f.writeAsStringSync(contents);
}
