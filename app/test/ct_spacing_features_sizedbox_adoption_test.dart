import 'dart:io';

import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('CtSpacing SizedBox gap adoption (Refs #2914 S5 follow-up)', () {
    // Visible-layout-preserving guard: a `SizedBox(height: N)` /
    // `SizedBox(width: N)` spacer migrates to `SizedBox(height:
    // CtSpacing.<token>)` only when `N` equals the token's logical px, so
    // the physical gap is unchanged. This pins the contract at the slice
    // boundary (matching the `EdgeInsets.all` guard above).
    test('CtSpacing tokens preserve the migrated SizedBox gap sizes', () {
      expect(CtSpacing.xs, 2);
      expect(CtSpacing.s, 6);
      expect(CtSpacing.m, 8);
      expect(CtSpacing.ml, 12);
      expect(CtSpacing.l, 16);
      expect(CtSpacing.xl, 20);
      expect(CtSpacing.xxl, 24);
    });

    test('the SizedBox gap detector flags raw token literals but not '
        'migrated or out-of-scale forms', () {
      final rawGap = RegExp(
        r'SizedBox\(\s*(?:height|width):\s*'
        r'(?:2|6|8|12|16|20|24)(?:\.0)?\s*\)',
      );
      // Positive: every in-scale token literal is detected.
      expect(rawGap.hasMatch('const SizedBox(height: 12)'), isTrue);
      expect(rawGap.hasMatch('const SizedBox(width: 6)'), isTrue);
      expect(rawGap.hasMatch('SizedBox(height: 16.0)'), isTrue);
      // Negative: migrated token references are not flagged.
      expect(rawGap.hasMatch('const SizedBox(height: CtSpacing.ml)'), isFalse);
      // Negative: out-of-scale magnitudes remain legitimate overrides.
      expect(rawGap.hasMatch('const SizedBox(height: 4)'), isFalse);
      expect(rawGap.hasMatch('const SizedBox(width: 10)'), isFalse);
      expect(rawGap.hasMatch('const SizedBox(height: 14)'), isFalse);
    });

    for (final relPath in _sizedBoxMigratedFiles) {
      test('$relPath has no raw SizedBox(height|width: N) for N in the '
          'migrated token set ({2, 6, 8, 12, 16, 20, 24})', () {
        final file = File(relPath);
        expect(
          file.existsSync(),
          isTrue,
          reason:
              'SizedBox-migrated feature file $relPath must exist; test '
              'was launched from ${Directory.current.path}.',
        );
        // Single-dimension `SizedBox(height: N)` / `SizedBox(width: N)`
        // gap spacers. Out-of-scale literals (`4`, `10`, `14`) are
        // intentionally NOT matched per `SPEC/ui/pixel-art-ui-catalog.md`
        // § Spacing tokens (they remain per-component overrides). Comment
        // lines are ignored so dartdoc can name the banned forms.
        final rawGap = RegExp(
          r'SizedBox\(\s*(?:height|width):\s*'
          r'(?:2|6|8|12|16|20|24)(?:\.0)?\s*\)',
        );
        final lines = file.readAsStringSync().split('\n');
        final bad = <String>[];
        for (var i = 0; i < lines.length; i++) {
          final raw = lines[i];
          if (raw.trimLeft().startsWith('//')) continue;
          if (rawGap.hasMatch(raw)) {
            bad.add('  L${i + 1}: ${raw.trim()}');
          }
        }
        expect(
          bad,
          isEmpty,
          reason:
              'Found ${bad.length} raw `SizedBox(height|width: N)` gap'
              '${bad.length == 1 ? '' : 's'} in $relPath for '
              'N ∈ {2, 6, 8, 12, 16, 20, 24}:\n'
              '${bad.join('\n')}\n'
              'Replace each token-set literal with `CtSpacing.<token>`: '
              '2 → CtSpacing.xs, 6 → CtSpacing.s, 8 → CtSpacing.m, '
              '12 → CtSpacing.ml, 16 → CtSpacing.l, 20 → CtSpacing.xl, '
              '24 → CtSpacing.xxl. Out-of-scale literals (e.g. `4`, '
              '`10`, `14`) may remain per SPEC § Spacing tokens.',
        );
      });
    }
  });
}

/// Dialogue-overlay feature files migrated to `CtSpacing` for
/// single-dimension `SizedBox(height|width: N)` gap spacers in the Refs
/// #2914 S5 follow-up slice (extends the `EdgeInsets.all` / `symmetric`
/// adoption above to the `SizedBox` gap surface named in
/// `SPEC/ui/pixel-art-ui-catalog.md` § Spacing tokens and
/// `app/lib/widgets/ct_spacing.dart`). Each file already appears in
/// `ctSpacingMigratedFeatureFiles`, so the `ct_spacing.dart` import and
/// `CtSpacing.<token>` reference invariants are covered there; this list
/// adds only the no-raw-`SizedBox`-token-gap invariant.
const List<String> _sizedBoxMigratedFiles = <String>[
  // game_start_intro_overlay.dart is a de-parted barrel (Refs #4117); build mixin
  // owns the SizedBox gap spacers.
  'lib/features/game/widgets/dialogue/game_start_intro_overlay_build.dart',
  'lib/features/game/widgets/dialogue/intervention_choice_buttons.dart',
  // intervention_dialogue_overlay.dart is a de-parted barrel; state module owns
  // the SizedBox gap spacers.
  'lib/features/game/widgets/dialogue/intervention_dialogue_overlay_state.dart',
  // overture_dialogue_overlay.dart is a de-parted barrel; state module owns the
  // SizedBox gap spacers.
  'lib/features/game/widgets/dialogue/overture_dialogue_overlay_state.dart',
  'lib/features/game/widgets/dialogue/overture_dialogue_overlay_offer_row.dart',
  'lib/features/game/widgets/dialogue/call_to_arms_dialogue_overlay.dart',
];
