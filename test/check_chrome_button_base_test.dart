// Refs #3594 — guards `repo.chrome_button_base` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_chrome_button_base.dart';

void main() {
  group('repo.chrome_button_base', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckChromeButtonBase(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_chrome_button_base: all chrome `*TextButton` states mix in '
          'CtHoverButtonStateMixin.',
        ),
      );
    });

    test('fails when a `*TextButton` state omits the canonical mixin', () {
      final temp = Directory.systemTemp.createTempSync('chrome_button_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final chromeDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets/chrome'),
      )..createSync(recursive: true);

      File(p.join(chromeDir.path, 'ct_sample_text_button.dart'))
          .writeAsStringSync(
            'class CtSampleTextButton extends StatefulWidget {\n'
            '  const CtSampleTextButton({super.key});\n'
            '  @override\n'
            '  State<CtSampleTextButton> createState() =>\n'
            '      _CtSampleTextButtonState();\n'
            '}\n'
            'class _CtSampleTextButtonState extends State<CtSampleTextButton> {\n'
            '  @override\n'
            '  Widget build(BuildContext context) => const SizedBox();\n'
            '}\n',
          );

      final errLogs = <String>[];
      final code = runCheckChromeButtonBase(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('ct_sample_text_button.dart'));
      expect(errLogs.join('\n'), contains('CtSampleTextButton'));
      expect(errLogs.join('\n'), contains('CtHoverButtonStateMixin'));
    });

    test('passes when a `*TextButton` state adopts the canonical mixin', () {
      final temp = Directory.systemTemp.createTempSync('chrome_button_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final chromeDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets/chrome'),
      )..createSync(recursive: true);

      File(p.join(chromeDir.path, 'ct_sample_text_button.dart'))
          .writeAsStringSync(
            'class CtSampleTextButton extends StatefulWidget {\n'
            '  const CtSampleTextButton({super.key});\n'
            '  @override\n'
            '  State<CtSampleTextButton> createState() =>\n'
            '      _CtSampleTextButtonState();\n'
            '}\n'
            'class _CtSampleTextButtonState extends State<CtSampleTextButton>\n'
            '    with CtHoverButtonStateMixin<CtSampleTextButton> {\n'
            '  @override\n'
            '  Widget build(BuildContext context) => const SizedBox();\n'
            '}\n',
          );

      final code = runCheckChromeButtonBase(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('ignores non-button states under chrome/', () {
      final temp = Directory.systemTemp.createTempSync('chrome_button_skip_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final chromeDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets/chrome'),
      )..createSync(recursive: true);

      // A non-`*TextButton` state (e.g. a panel) must not be gated.
      File(p.join(chromeDir.path, 'ct_sample_panel.dart')).writeAsStringSync(
        'class CtSamplePanel extends StatefulWidget {\n'
        '  const CtSamplePanel({super.key});\n'
        '  @override\n'
        '  State<CtSamplePanel> createState() => _CtSamplePanelState();\n'
        '}\n'
        'class _CtSamplePanelState extends State<CtSamplePanel> {\n'
        '  @override\n'
        '  Widget build(BuildContext context) => const SizedBox();\n'
        '}\n',
      );

      final code = runCheckChromeButtonBase(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}
