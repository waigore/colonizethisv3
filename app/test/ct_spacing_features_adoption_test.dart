import 'dart:io';

import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

/// Pinning tests for `CtSpacing` adoption in `app/lib/features/**.dart`
/// (Refs #2914 S5 follow-up to PR #3085, which restricted scope to the
/// Ct-* widget defaults). This slice adopts `CtSpacing.{m,ml,l,xl,xxl}` in
/// place of raw `EdgeInsets.all({8,12,16,20,24})` and
/// `EdgeInsets.symmetric(horizontal|vertical: {8,12,16,20,24})` literals
/// across the targeted feature files so per-screen padding flows from
/// the SPEC-pinned scale instead of magic numbers.
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens* —
/// authoritative table; the `s` token row explicitly names
/// `EdgeInsets.symmetric(horizontal: s, vertical: 4)`-style usage as the
/// adoption surface this test enforces; § *Spacing and radius tokens*
/// prose ("per-component review (issues #2914 S5 / S6) can adopt them in
/// Ct-\* widget defaults **and feature padding/radius callsites**") +
/// § *Acceptance criteria (Spacing and radius tokens)* AC #3 pin the
/// constant table that this test extends to the per-feature
/// `EdgeInsets.symmetric` surface.
///
/// Adoption rule (this slice):
/// * Every file listed in `_migratedFeatureFiles` MUST import
///   `package:colonizethis_app/widgets/ct_spacing.dart` (relatively or by
///   package URI), declare at least one `CtSpacing.<token>` reference,
///   and MUST NOT contain a raw `EdgeInsets.all({8,12,16,20,24})` literal
///   nor a raw `EdgeInsets.symmetric(horizontal|vertical: N)` named-arg
///   literal for the same token set. Other `EdgeInsets.*` forms
///   (`only`, `fromLTRB`) are out-of-scope for this slice and are not
///   enforced here.
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
          // is tolerated. Other `EdgeInsets.*` forms (`only`, `fromLTRB`)
          // remain out-of-scope for this slice; `symmetric` is enforced
          // by the sibling test below per `SPEC/ui/pixel-art-ui-catalog.md`
          // § Spacing tokens (which names
          // `EdgeInsets.symmetric(horizontal: s, vertical: 4)`-style
          // usage as an explicit token-adoption surface for `s`).
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

        test(
            'no raw EdgeInsets.symmetric named arg for N in the migrated '
            'token set ({8, 12, 16, 20, 24})', () {
          // Pattern matches a `horizontal:` or `vertical:` named arg with
          // a raw literal value from the migrated token set inside any
          // `EdgeInsets.symmetric(...)` call, allowing the arg to sit on
          // its own line (split-arg form). Out-of-scale literals like
          // `4` and `6` are intentionally NOT matched: SPEC §Spacing
          // tokens explicitly leaves them as per-component overrides
          // (the example `EdgeInsets.symmetric(horizontal: s, vertical: 4)`
          // keeps the `4` as a literal). Mixed callsites where ONE arg
          // is in the token set and the other is out-of-scale must
          // still migrate the token-set arg through `CtSpacing.<token>`.
          //
          // The check ignores comments by trimming source lines whose
          // first non-whitespace char is `//`.
          final symmetricArg = RegExp(
            r'\b(horizontal|vertical):\s*(8|12|16|20|24)(?:\.0)?\s*[,)]',
          );
          final lines = source.split('\n');
          final List<String> bad = <String>[];
          bool insideSymmetric = false;
          for (var i = 0; i < lines.length; i++) {
            final raw = lines[i];
            final trimmed = raw.trimLeft();
            if (trimmed.startsWith('//')) continue;
            // Track whether the current line lies inside an
            // `EdgeInsets.symmetric(` argument list. A line either
            // opens one (`EdgeInsets.symmetric(`) or closes one (`)`).
            // The same-line literal form is caught by the single-line
            // match below.
            final opensSymmetric = raw.contains('EdgeInsets.symmetric(');
            if (opensSymmetric) {
              // Same-line `EdgeInsets.symmetric(... N ...)` form.
              final sym = RegExp(
                r'EdgeInsets\.symmetric\([^)]*\b(horizontal|vertical):\s*(?:8|12|16|20|24)(?:\.0)?\s*[,)]',
              );
              if (sym.hasMatch(raw)) {
                bad.add('  L${i + 1}: ${raw.trim()}');
              }
              // Open the multi-line tracker only when the call does NOT
              // also close on the same line (no trailing `)` after the
              // last `(`).
              final openIdx = raw.lastIndexOf('EdgeInsets.symmetric(');
              final tail = raw.substring(openIdx);
              if (!tail.contains(')')) {
                insideSymmetric = true;
              }
              continue;
            }
            if (insideSymmetric) {
              if (symmetricArg.hasMatch(raw)) {
                bad.add('  L${i + 1}: ${raw.trim()}');
              }
              if (raw.contains(')')) {
                insideSymmetric = false;
              }
            }
          }
          expect(
            bad,
            isEmpty,
            reason:
                'Found ${bad.length} raw `EdgeInsets.symmetric` named arg'
                '${bad.length == 1 ? '' : 's'} in $relPath for '
                'horizontal/vertical ∈ {8, 12, 16, 20, 24}:\n'
                '${bad.join('\n')}\n'
                'Replace each token-set literal with `CtSpacing.<token>`: '
                '8 → CtSpacing.m, 12 → CtSpacing.ml, 16 → CtSpacing.l, '
                '20 → CtSpacing.xl, 24 → CtSpacing.xxl. Out-of-scale '
                'literals (e.g. `4`, `6`) may remain per SPEC '
                '§ Spacing tokens.',
          );
        });
      });
    }
  });
}

/// Feature files migrated to `CtSpacing` for `EdgeInsets.all(N)` and
/// `EdgeInsets.symmetric(horizontal|vertical: N)` callsites in the Refs
/// #2914 S5 follow-up slice. Paths are relative to the `app/` package
/// root (the working directory for `flutter test app/...`).
///
/// Adding a feature file to this list MUST be paired with the four
/// invariants verified above: import in place, at least one
/// `CtSpacing.<token>` reference, no raw `EdgeInsets.all(N)` for
/// `N ∈ {8, 12, 16, 20, 24}`, and no raw `EdgeInsets.symmetric` named
/// arg literal for the same token set.
const List<String> _migratedFeatureFiles = <String>[
  'lib/features/game/combat/quick_battle_deployment_view.dart',
  'lib/features/game/dialogue/game_start_intro_overlay.dart',
  'lib/features/game/dialogue/intervention_dialogue_overlay.dart',
  'lib/features/game/dialogue/overture_dialogue_overlay.dart',
  'lib/features/game/flame/game_side_menu.dart',
  'lib/features/game/flame/next_turn_confirmation_dialog.dart',
  'lib/features/game/flame/victory_overlay.dart',
  'lib/features/game/screens/technology_screen.dart',
  'lib/features/game/screens/trade_screen.dart',
  'lib/features/game/screens/trade_screen_deal_book.dart',
  'lib/features/game/widgets/civilian_units_panel.dart',
  'lib/features/game/widgets/civilian_units_panel_support.dart',
  'lib/features/game/widgets/diplomacy_panel.dart',
  'lib/features/game/widgets/diplomacy_panel_chrome.dart',
  'lib/features/game/widgets/diplomacy_panel_mode_bar.dart',
  'lib/features/game/widgets/game_tab_bar.dart',
  'lib/features/game/widgets/military_units_panel.dart',
  'lib/features/game/widgets/move_army_dialog.dart',
  'lib/features/game/widgets/move_fleet_dialog.dart',
  'lib/features/game/widgets/observe_mode_not_defined_panel.dart',
  'lib/features/game/widgets/pause_menu_panel.dart',
  'lib/features/game/widgets/production_allocation_row_chrome.dart',
  'lib/features/game/widgets/production_commodity_breakdown_dialog.dart',
  'lib/features/game/widgets/production_panel.dart',
  'lib/features/game/widgets/province_sea_zone_detail_overlay.dart',
  'lib/features/game/widgets/split_army_dialog.dart',
  'lib/features/game/widgets/split_fleet_dialog.dart',
  'lib/features/game/widgets/technology_panel.dart',
  'lib/features/game/widgets/technology_panel_orders.dart',
  'lib/features/game/widgets/train_civilians_dialog.dart',
  'lib/features/game/widgets/train_dialog_chrome.dart',
  'lib/features/game/widgets/train_military_dialog.dart',
  'lib/features/game/widgets/transfer_to_home_fleet_dialog.dart',
  'lib/features/game/widgets/turn_news_dialog.dart',
  'lib/features/game/widgets/units/shared/units_panel_row_chrome.dart',
  'lib/features/game/widgets/units/shared/units_panel_shell.dart',
  'lib/features/shell/new_game_setup_flow.dart',
];
