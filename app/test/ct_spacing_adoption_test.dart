import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pinning tests for `CtSpacing` adoption in Ct-* widget defaults
/// (Refs #2914 S5).
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens* —
/// authoritative table; § *CtNinePatchButton*, § *CtResourceCell*, and
/// § *CtChoiceChip* (catalog) pin the per-widget default padding
/// contracts that resolve through these tokens.
///
/// Asserts default padding values for the Ct-* widget defaults migrated
/// in this slice resolve to the canonical `CtSpacing.*` constants rather
/// than embedding raw literals. The matching SPEC text reads the
/// adoption as: "every Dart constant name and value matches a row in
/// the corresponding token table and no extra named constants exist".
void main() {
  suppressLogsForTests();

  group('CtNinePatchButton default padding resolves through CtSpacing', () {
    test('CtNinePatchButton.defaultPadding = (CtSpacing.l, CtSpacing.ml)', () {
      expect(
        CtNinePatchButton.defaultPadding,
        const EdgeInsets.symmetric(
          horizontal: CtSpacing.l,
          vertical: CtSpacing.ml,
        ),
      );
    });

    test(
        'CtNinePatchButton.defaultPadding resolves to the legacy '
        '(16, 12) inset', () {
      // The legacy nine-patch button used `EdgeInsets.symmetric(horizontal:
      // 16, vertical: 12)` directly. The migration to CtSpacing tokens must
      // preserve the same physical inset so visible layouts do not shift.
      expect(
        CtNinePatchButton.defaultPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    });
  });

  group('CtChoiceChip default padding resolves through CtSpacing', () {
    test('CtChoiceChip.defaultPadding = (CtSpacing.m, 4)', () {
      // Horizontal token from the SPEC scale; vertical `4` is an
      // out-of-scale per-component override called out in
      // SPEC/ui/pixel-art-ui-catalog.md § *Spacing tokens* prose
      // ("The scale is intentionally non-linear: it skips over 4, 10,
      // and 14").
      expect(
        CtChoiceChip.defaultPadding,
        const EdgeInsets.symmetric(
          horizontal: CtSpacing.m,
          vertical: 4,
        ),
      );
    });

    test('CtChoiceChip.defaultPadding resolves to the legacy (8, 4) inset', () {
      expect(
        CtChoiceChip.defaultPadding,
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
    });
  });

  group('CtResourceCell default padding resolves through CtSpacing', () {
    test('default constructor padding = (CtSpacing.s, 4)', () {
      // Construct a default CtResourceCell and read back the
      // canonical default padding through the public field. The cell
      // constructor pins horizontal to `CtSpacing.s` (6 px) and keeps
      // vertical `4` as the mockup-pinned per-component override.
      final cell = CtResourceCell(
        iconBuilder: (_) => const SizedBox(width: 20, height: 20),
        name: 'Wool',
        quantity: 1,
      );
      expect(
        cell.padding,
        const EdgeInsets.symmetric(horizontal: CtSpacing.s, vertical: 4),
      );
      expect(
        cell.padding,
        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      );
    });
  });
}
