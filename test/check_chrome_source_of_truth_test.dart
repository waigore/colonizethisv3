import 'dart:io';

import 'package:test/test.dart';

/// Structural gate for issue #3594 item 5: the shared chrome widgets
/// `CtDialogShell`, `CtPanel`, and `CtNinePatchButton` have their
/// implementation (source of truth) in `app/lib/widgets/`, and the
/// `features/game/widgets/chrome/` counterparts are thin re-export shims that
/// point back up to `widgets/`. This pins the dependency direction
/// (features -> widgets), preventing regression to the previously inverted
/// chain where shared widgets re-exported feature-level implementations.
void main() {
  const chromeWidgets = <String, String>{
    'ct_dialog_shell': 'CtDialogShell',
    'ct_panel': 'CtPanel',
    'ct_nine_patch_button': 'CtNinePatchButton',
  };

  for (final entry in chromeWidgets.entries) {
    final fileName = entry.key;
    final className = entry.value;

    test('$className implementation lives in app/lib/widgets/$fileName.dart',
        () {
      final impl = File('app/lib/widgets/$fileName.dart');
      expect(
        impl.existsSync(),
        isTrue,
        reason: 'Expected source-of-truth at ${impl.path}',
      );
      final source = impl.readAsStringSync();
      expect(
        source,
        contains('class $className'),
        reason: '$fileName.dart in widgets/ must declare $className '
            '(real implementation, not just a re-export).',
      );
    });

    test('chrome/$fileName.dart is a re-export shim pointing to widgets/', () {
      final shim = File(
        'app/lib/features/game/widgets/chrome/$fileName.dart',
      );
      expect(
        shim.existsSync(),
        isTrue,
        reason: 'Expected chrome re-export shim at ${shim.path}',
      );
      final source = shim.readAsStringSync();
      expect(
        source,
        contains("export '../../../../widgets/$fileName.dart';"),
        reason: 'chrome/$fileName.dart must re-export the widgets/ source of '
            'truth (features -> widgets direction).',
      );
      expect(
        source.contains('class $className'),
        isFalse,
        reason: 'chrome/$fileName.dart must not contain a $className '
            'implementation; it is a re-export shim only.',
      );
    });
  }
}
