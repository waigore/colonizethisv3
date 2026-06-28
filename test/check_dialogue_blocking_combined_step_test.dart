// Refs #3628 / #3750 — guards `repo.dialogue_blocking_combined_step`
// enforcement of the collapsed single-step blocking-dialogue contract.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_dialogue_blocking_combined_step.dart';

/// Writes a dialogue overlay/source file into a temp repo's dialogue dir.
void _writeDialogueFile(String repoRoot, String basename, String source) {
  final dir = Directory(p.join(repoRoot, 'app/lib/features/game/dialogue'))
    ..createSync(recursive: true);
  File(p.join(dir.path, basename)).writeAsStringSync(source);
}

/// Writes the combined-step golden test file importing [overlayBasenames].
void _writeGoldenTest(String repoRoot, List<String> overlayBasenames) {
  final dir = Directory(p.join(repoRoot, 'app/test'))
    ..createSync(recursive: true);
  final imports = overlayBasenames
      .map(
        (b) =>
            "import 'package:colonizethis_app/features/game/dialogue/$b';",
      )
      .join('\n');
  File(
    p.join(dir.path, 'dialogue_combined_line_choice_goldens_test.dart'),
  ).writeAsStringSync('$imports\n\nvoid main() {}\n');
}

const String _compliantOverlay = '''
import 'ct_dialogue_view.dart';
import 'ct_dialogue_line_choice_body.dart';

Widget buildBody() {
  final view = CtDialogueView();
  return CtDialogueLineChoiceBody(view: view, continueLabel: 'ok');
}
''';

void main() {
  group('repo.dialogue_blocking_combined_step', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckDialogueBlockingCombinedStep(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_dialogue_blocking_combined_step: blocking dialogue overlays '
          'adopt CtDialogueLineChoiceBody and combined-step goldens are in '
          'parity.',
        ),
      );
    });

    test('passes for a compliant overlay registered in the golden test', () {
      final temp = Directory.systemTemp.createTempSync('dlg_combined_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeDialogueFile(temp.path, 'herald_overlay.dart', _compliantOverlay);
      _writeGoldenTest(temp.path, ['herald_overlay.dart']);

      final logs = <String>[];
      final code = runCheckDialogueBlockingCombinedStep(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('Check 1: fails when CtDialogueView is built without the body', () {
      final temp = Directory.systemTemp.createTempSync('dlg_combined_c1_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeDialogueFile(temp.path, 'herald_overlay.dart', '''
import 'ct_dialogue_view.dart';

Widget buildBody() {
  final view = CtDialogueView();
  return SomeOtherBody(view: view);
}
''');
      // Registered in the golden test so only Check 1 fires.
      _writeGoldenTest(temp.path, ['herald_overlay.dart']);

      final errLogs = <String>[];
      final code = runCheckDialogueBlockingCombinedStep(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      final out = errLogs.join('\n');
      expect(code, 1);
      expect(out, contains('[adoption]'));
      expect(out, contains('herald_overlay.dart'));
      expect(out, contains('CtDialogueLineChoiceBody'));
    });

    test('Check 2: fails when an overlay wires advanceLine on the view', () {
      final temp = Directory.systemTemp.createTempSync('dlg_combined_c2_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeDialogueFile(temp.path, 'herald_overlay.dart', '''
import 'ct_dialogue_view.dart';
import 'ct_dialogue_line_choice_body.dart';

Widget buildBody() {
  final view = CtDialogueView();
  return CtButton(onPressed: () => view.advanceLine(), child: body(view));
}

Widget body(CtDialogueView view) =>
    CtDialogueLineChoiceBody(view: view, continueLabel: 'ok');
''');
      // Registered in the golden test so only Check 2 fires.
      _writeGoldenTest(temp.path, ['herald_overlay.dart']);

      final errLogs = <String>[];
      final code = runCheckDialogueBlockingCombinedStep(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      final out = errLogs.join('\n');
      expect(code, 1);
      expect(out, contains('[wiring]'));
      expect(out, contains('advanceLine'));
      expect(out, contains('herald_overlay.dart'));
    });

    test('Check 2: also catches selectOption tear-off references', () {
      final temp = Directory.systemTemp.createTempSync('dlg_combined_c2b_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeDialogueFile(temp.path, 'herald_overlay.dart', '''
import 'ct_dialogue_view.dart';
import 'ct_dialogue_line_choice_body.dart';

Widget buildBody() {
  final view = CtDialogueView();
  final cb = view.confirmCombinedLineOption;
  return CtDialogueLineChoiceBody(view: view, continueLabel: 'ok', cb: cb);
}
''');
      _writeGoldenTest(temp.path, ['herald_overlay.dart']);

      final errLogs = <String>[];
      final code = runCheckDialogueBlockingCombinedStep(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      final out = errLogs.join('\n');
      expect(code, 1);
      expect(out, contains('[wiring]'));
      expect(out, contains('confirmCombinedLineOption'));
    });

    test('Check 3: fails when a view overlay is missing from goldens', () {
      final temp = Directory.systemTemp.createTempSync('dlg_combined_c3_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeDialogueFile(temp.path, 'herald_overlay.dart', _compliantOverlay);
      // Golden test imports nothing — the new overlay is unregistered.
      _writeGoldenTest(temp.path, const []);

      final errLogs = <String>[];
      final code = runCheckDialogueBlockingCombinedStep(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      final out = errLogs.join('\n');
      expect(code, 1);
      expect(out, contains('[golden-registry]'));
      expect(out, contains('herald_overlay.dart'));
      expect(out, contains('not imported by'));
    });

    test('Check 3: fails on a stale golden import with no view overlay', () {
      final temp = Directory.systemTemp.createTempSync('dlg_combined_c3b_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeDialogueFile(temp.path, 'herald_overlay.dart', _compliantOverlay);
      // Golden imports a ghost overlay that does not exist in code.
      _writeGoldenTest(temp.path, [
        'herald_overlay.dart',
        'ghost_overlay.dart',
      ]);

      final errLogs = <String>[];
      final code = runCheckDialogueBlockingCombinedStep(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      final out = errLogs.join('\n');
      expect(code, 1);
      expect(out, contains('[golden-registry]'));
      expect(out, contains('ghost_overlay.dart'));
      expect(out, contains('stale'));
    });

    test('exempts call_to_arms overlay (no CtDialogueView, not in set)', () {
      final temp = Directory.systemTemp.createTempSync('dlg_combined_exempt_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeDialogueFile(
        temp.path,
        'call_to_arms_dialogue_overlay.dart',
        '''
import 'package:flutter/material.dart';

Widget buildBody() => const ColoredBox(color: Color(0xFF101014));
''',
      );
      _writeGoldenTest(temp.path, const []);

      final logs = <String>[];
      final code = runCheckDialogueBlockingCombinedStep(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('returns 1 when the golden test file is missing', () {
      final temp = Directory.systemTemp.createTempSync('dlg_combined_nogold_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeDialogueFile(temp.path, 'herald_overlay.dart', _compliantOverlay);

      final errLogs = <String>[];
      final code = runCheckDialogueBlockingCombinedStep(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('dialogue_combined_line_choice_goldens_test.dart'),
      );
    });
  });
}
