import 'dart:io';

import 'package:test/test.dart';

/// Structural gate for issue #3594 item 5 + #4035 AC2: shared chrome widgets
/// live under `app/lib/widgets/` (source of truth). The former
/// `features/game/widgets/chrome/` shims / leftover implementations are
/// deleted so call sites cannot reintroduce the feature-layer chrome home.
void main() {
  const chromeWidgets = <String, String>{
    'ct_dialog_shell': 'CtDialogShell',
    'ct_panel': 'CtPanel',
    'ct_nine_patch_button': 'CtNinePatchButton',
    'ct_action_text_button': 'CtActionTextButton',
    'ct_danger_text_button': 'CtDangerTextButton',
    'ct_circular_locate_button': 'CtCircularLocateButton',
    'ct_hover_button': 'CtHoverButtonStateMixin',
  };

  test('features/game/widgets/chrome/ directory is removed', () {
    final chromeDir = Directory('app/lib/features/game/widgets/chrome');
    expect(
      chromeDir.existsSync(),
      isFalse,
      reason: 'Feature chrome shims must be deleted; import '
          'package:colonizethis_app/widgets/... instead (Refs #4035 AC2).',
    );
  });

  for (final entry in chromeWidgets.entries) {
    final fileName = entry.key;
    final symbolName = entry.value;

    test('$symbolName implementation lives in app/lib/widgets/$fileName.dart',
        () {
      final impl = File('app/lib/widgets/$fileName.dart');
      expect(
        impl.existsSync(),
        isTrue,
        reason: 'Expected source-of-truth at ${impl.path}',
      );
      final source = impl.readAsStringSync();
      final declaration = fileName == 'ct_hover_button'
          ? 'mixin $symbolName'
          : 'class $symbolName';
      expect(
        source,
        contains(declaration),
        reason: '$fileName.dart in widgets/ must declare $symbolName '
            '(real implementation, not just a re-export).',
      );
    });
  }
}
