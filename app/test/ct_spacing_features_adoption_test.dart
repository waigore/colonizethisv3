import 'dart:io';

import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

/// Pinning tests for `CtSpacing` adoption in `app/lib/features/**.dart`
/// (Refs #2914 S5 follow-up to PR #3085, which restricted scope to the
/// Ct-* widget defaults). This slice adopts `CtSpacing.{m,ml,l,xl,xxl}` in
/// place of raw `EdgeInsets.all({8,12,16,20,24})` literals across the
/// targeted feature files so per-screen padding flows from the SPEC-pinned
/// scale instead of magic numbers.
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens* —
/// authoritative table; § *Spacing and radius tokens* prose explicitly
/// names this slice ("per-component review (issues #2914 S5 / S6) can
/// adopt them in Ct-\* widget defaults **and feature padding/radius
/// callsites**"); § *Acceptance criteria (Spacing and radius tokens)*
/// AC #3 pins the constant table; this test pins the per-feature
/// adoption surface.
///
/// Adoption rule (this slice):
/// * Every file listed in `_migratedFeatureFiles` MUST import
///   `package:colonizethis_app/widgets/ct_spacing.dart` (relatively or by
///   package URI), declare at least one `CtSpacing.<token>` reference,
///   and MUST NOT contain a raw `EdgeInsets.all({8,12,16,20,24})` literal
///   for the migrated token set. Other `EdgeInsets.*` forms
///   (`symmetric`, `only`, `fromLTRB`) are out-of-scope for this slice
///   and are not enforced here.
///
/// Visible layout is preserved because each replacement keeps the same
/// physical inset (`CtSpacing.m == 8`, `ml == 12`, `l == 16`,
/// `xl == 20`, `xxl == 24`).
void main() {
  suppressLogsForTests();

  group('CtSpacing feature-file adoption (Refs #2914 S5 follow-up)', () {
    test('CtSpacing tokens preserve the migrated physical insets', () {
      // Visible-layout-preserving guard: the migration substitutes
      // `EdgeInsets.all(N)` → `EdgeInsets.all(CtSpacing.<token>)` and
      // therefore depends on the SPEC-pinned values 8 / 12 / 16 / 20 /
      // 24 mapping cleanly to `m` / `ml` / `l` / `xl` / `xxl`. If a
      // future SPEC change re-points one of these tokens, every site in
      // `_migratedFeatureFiles` shifts together — that is by design, but
      // it MUST be a deliberate SPEC change and not an accidental
      // refactor; this test pins the contract at the slice boundary.
      expect(CtSpacing.m, 8);
      expect(CtSpacing.ml, 12);
      expect(CtSpacing.l, 16);
      expect(CtSpacing.xl, 20);
      expect(CtSpacing.xxl, 24);
    });

    for (final relPath in _migratedFeatureFiles) {
      group(relPath, () {
        late final String source;

        setUpAll(() {
          final file = File(relPath);
          expect(
            file.existsSync(),
            isTrue,
            reason:
                'Migrated feature file $relPath must exist; test was '
                'launched from ${Directory.current.path}.',
          );
          source = file.readAsStringSync();
        });

        test('imports CtSpacing (or is a `part of` whose parent imports it)',
            () {
          // `part of` files inherit imports from the parent library, so
          // they can use `CtSpacing.<token>` without their own import
          // directive (Dart 3 part-of contract). For those files, this
          // test asserts the parent library imports `ct_spacing.dart`
          // instead of the part file itself.
          final partOfMatch = RegExp(r"^\s*part of '([^']+)';", multiLine: true)
              .firstMatch(source);
          final String fileToCheck;
          final String sourceToCheck;
          if (partOfMatch != null) {
            final parentRel = partOfMatch.group(1)!;
            // `part of '../foo.dart';` is resolved relative to the
            // part file's directory; for this slice the only `part of`
            // file uses a same-directory parent so `dirname + parentRel`
            // yields the parent library file path.
            final dir = File(relPath).parent.path;
            fileToCheck = '$dir/$parentRel';
            sourceToCheck = File(fileToCheck).readAsStringSync();
          } else {
            fileToCheck = relPath;
            sourceToCheck = source;
          }
          final hasImport =
              sourceToCheck.contains("widgets/ct_spacing.dart") ||
              sourceToCheck.contains(
                "package:colonizethis_app/widgets/ct_spacing.dart",
              );
          expect(
            hasImport,
            isTrue,
            reason:
                '$fileToCheck must import `widgets/ct_spacing.dart` '
                '(relative or by package URI) so the migrated '
                '`EdgeInsets.all` callsites in $relPath can reference '
                '`CtSpacing.<token>` constants.',
          );
        });

        test('declares at least one CtSpacing.<token> reference', () {
          // Library files may delegate the actual `CtSpacing.<token>`
          // callsite to a sibling `part 'x.dart';` file; include those
          // parts when checking the reference so the import is not
          // misread as dead.
          final tokenRegex = RegExp(r'CtSpacing\.(xs|s|m|ml|l|xl|xxl)\b');
          bool hasTokenReference = tokenRegex.hasMatch(source);
          if (!hasTokenReference) {
            final partRegex = RegExp(
              r"^\s*part\s+'([^']+)';",
              multiLine: true,
            );
            final dir = File(relPath).parent.path;
            for (final m in partRegex.allMatches(source)) {
              final partRel = m.group(1)!;
              final partPath = '$dir/$partRel';
              final partFile = File(partPath);
              if (partFile.existsSync() &&
                  tokenRegex.hasMatch(partFile.readAsStringSync())) {
                hasTokenReference = true;
                break;
              }
            }
          }
          expect(
            hasTokenReference,
            isTrue,
            reason:
                '$relPath (or one of its `part` files) must contain at '
                'least one `CtSpacing.<token>` reference once the '
                '`widgets/ct_spacing.dart` import is in place — '
                'otherwise the import is dead and the adoption is '
                'incomplete.',
          );
        });

        test(
            'no raw EdgeInsets.all(N) for N in the migrated token set '
            '({8, 12, 16, 20, 24})', () {
          // Pattern matches `EdgeInsets.all(8)`, `EdgeInsets.all(12.0)`,
          // and similar literal forms. Whitespace inside the parentheses
          // is tolerated. Other `EdgeInsets.*` forms (`symmetric`,
          // `only`, `fromLTRB`) are intentionally out-of-scope for this
          // slice and not enforced here.
          final rawAll = RegExp(
            r'EdgeInsets\.all\(\s*(?:8|12|16|20|24)(?:\.0)?\s*\)',
          );
          final matches = rawAll.allMatches(source).toList();
          expect(
            matches,
            isEmpty,
            reason:
                'Found ${matches.length} raw `EdgeInsets.all(N)` literal'
                '${matches.length == 1 ? '' : 's'} in $relPath for N in '
                '{8, 12, 16, 20, 24}. Replace each with the matching '
                '`CtSpacing.<token>` constant: '
                '8 → CtSpacing.m, 12 → CtSpacing.ml, 16 → CtSpacing.l, '
                '20 → CtSpacing.xl, 24 → CtSpacing.xxl '
                '(SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § Spacing tokens).',
          );
        });
      });
    }
  });
}

/// Feature files migrated to `CtSpacing` for `EdgeInsets.all(N)` callsites
/// in the Refs #2914 S5 follow-up slice. Paths are relative to the `app/`
/// package root (the working directory for `flutter test app/...`).
///
/// Adding a feature file to this list MUST be paired with the same three
/// invariants verified above: import in place, at least one
/// `CtSpacing.<token>` reference, and no raw `EdgeInsets.all(N)` for
/// `N ∈ {8, 12, 16, 20, 24}`.
const List<String> _migratedFeatureFiles = <String>[
  'lib/features/game/combat/quick_battle_deployment_view.dart',
  'lib/features/game/dialogue/game_start_intro_overlay.dart',
  'lib/features/game/dialogue/intervention_dialogue_overlay.dart',
  'lib/features/game/dialogue/overture_dialogue_overlay.dart',
  'lib/features/game/flame/game_side_menu.dart',
  'lib/features/game/flame/victory_overlay.dart',
  'lib/features/game/screens/technology_screen.dart',
  'lib/features/game/screens/trade_screen.dart',
  'lib/features/game/screens/trade_screen_deal_book.dart',
  'lib/features/game/widgets/civilian_units_panel.dart',
  'lib/features/game/widgets/civilian_units_panel_support.dart',
  'lib/features/game/widgets/diplomacy_panel.dart',
  'lib/features/game/widgets/military_units_panel.dart',
  'lib/features/game/widgets/observe_mode_not_defined_panel.dart',
  'lib/features/game/widgets/pause_menu_panel.dart',
  'lib/features/game/widgets/production_panel.dart',
  'lib/features/game/widgets/province_sea_zone_detail_overlay.dart',
  'lib/features/game/widgets/split_army_dialog.dart',
  'lib/features/game/widgets/split_fleet_dialog.dart',
  'lib/features/game/widgets/technology_panel.dart',
  'lib/features/game/widgets/technology_panel_orders.dart',
  'lib/features/game/widgets/train_dialog_chrome.dart',
  'lib/features/game/widgets/transfer_to_home_fleet_dialog.dart',
  'lib/features/game/widgets/units/shared/units_panel_shell.dart',
  'lib/features/shell/new_game_setup_flow.dart',
];
