// Pin the 320 dp minimum-viewport contract for [ChooseTechDialog]
// (the Technology-panel slot picker, GAME40001) — sibling to
// `dialogs_320dp_min_viewport_test.dart` and the per-dialog narrow pins
// (`grant_or_subsidy_dialog_320dp_min_viewport_test.dart`,
// `production_commodity_breakdown_dialog_320dp_min_viewport_test.dart`).
//
// `ChooseTechDialog` is the dark editorial-monocle modal opened from a
// `TechnologyPanel` research slot's "Choose tech" action
// (`SPEC/ui/technology-panel.md` § Choose-tech dialog,
// `app/lib/features/game/widgets/technology_panel_orders.dart`). It wraps
// a [CtDialogShell] containing an accent title, a vertical column of
// bordered `_ChooseTechOptionRow` entries — each an icon + an `Expanded`
// name / era·category·cost label column — (or the muted empty-state
// line), and a single full-width Close `CtNinePatchButton`. At
// `kMinViewportWidth` (320 dp) the outer `Dialog.insetPadding` (16 dp
// each side) dominates the catalog `maxWidth`, collapsing the shell to
// ~288 dp content width — the same budget every other dialog pinned in
// `dialogs_320dp_min_viewport_test.dart` shares. The `Expanded` label
// column inside each option row is the part most at risk of horizontal
// overflow at this width, so the populated fixture deliberately uses the
// three longest catalog display names to stress the option-row Row.
//
// Three cases plus a wide regression sentinel cover the populated and
// empty modes:
//
//  * Populated (three longest-name catalog techs) — pins the title, each
//    option's localized display name, and the trailing Close action all
//    wrapping within the ~288 dp budget without a RenderFlex overflow.
//  * Empty state (no available techs) — pins the muted
//    "No techs available to research" line + Close within the same
//    budget.
//  * Negative control at 1024 × 768 dp pumps the populated fixture
//    without exception so a regression in the host overflow contract
//    upstream of the dialog itself would be caught.
//
// The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the other
//    `*_320dp_min_viewport_test.dart` files rely on.
//  * Localized title + each option display name + the Close label render
//    end-to-end so the layout actually exercises the dialog body at
//    320 dp rather than no-op'ing.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/technology-panel.md` § Choose-tech dialog.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel_orders.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show TechDefinition, techCatalog, techDisplayName;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/min_viewport_harness.dart';

/// Minimum supported viewport dimensions for `SPEC/ui/mobile-adaptation.md`
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same dialog renders its default layout. Mirrors the
/// contract used by `dialogs_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// The three catalog techs with the longest display names. These are the
/// worst case for the option-row `Expanded` label column at 320 dp, so
/// they make the narrow overflow pin meaningful rather than relying on a
/// short, easy-to-fit name.
List<TechDefinition> _longestNamedTechs() {
  final all = techCatalog.values.toList()
    ..sort((a, b) {
      final lenCmp =
          (b.displayName ?? '').length.compareTo((a.displayName ?? '').length);
      if (lenCmp != 0) return lenCmp;
      // Deterministic tiebreak by id so the fixture is stable across runs.
      return a.id.compareTo(b.id);
    });
  return all.take(3).toList();
}

/// Pumps [dialog] at [size] under the running editorial-monocle theme.
///
/// Delegates to the shared `pumpAtMinViewport` harness
/// — which sets the
/// surface size (so the binding's render flex math sees the minimum
/// viewport) and overrides MediaQuery so dialog code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value.
///
/// Embeds [dialog] directly in the Scaffold body rather than driving the
/// real `showDialog` flow because the contract under test is the dialog's
/// own `CtDialogShell` layout at the narrow viewport, not the barrier /
/// overlay route plumbing (already covered by
/// `technology_panel_choose_tech_dialog_test.dart`).
Future<void> _pumpDialog(
  WidgetTester tester,
  Widget dialog, {
  required Size size,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: Scaffold(body: Center(child: dialog)),
    settle: true,
  );
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — ChooseTechDialog (GAME40001) '
    '@ 320 dp (Refs #2870 S8/S10)',
    () {
      testWidgets(
        'AC (positive) ChooseTechDialog (3 longest-name techs) @ 320×640: '
        'no RenderFlex overflow exception, "Choose Tech — Slot 1" title + '
        'each option display name + Close label render — the bordered '
        'option rows (icon + Expanded name/meta column) and the trailing '
        'full-width Close CtNinePatchButton must wrap within the ~288 dp '
        'CtDialogShell content column per '
        'SPEC/ui/technology-panel.md § Choose-tech dialog.',
        (WidgetTester tester) async {
          final techs = _longestNamedTechs();

          await _pumpDialog(
            tester,
            ChooseTechDialog(
              slotIndex: 0,
              availableTechs: techs,
              onSelect: (_) {},
            ),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: ChooseTechDialog must '
                'not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The accent title, each '
                'bordered option row (StrictAssetIcon + Expanded name / '
                'era·category·cost label column), and the trailing Close '
                'CtNinePatchButton must wrap within the ~288 dp content '
                'width.',
          );
          // Title renders for the 1-based slot label.
          expect(find.text('Choose Tech \u2014 Slot 1'), findsOneWidget);
          // Each option's localized display name surfaces so the dialog
          // body is actually exercised at the narrow size (vs a no-op).
          for (final tech in techs) {
            expect(find.text(techDisplayName(tech.id)), findsOneWidget);
          }
          expect(find.text('Close'), findsOneWidget);
          // Empty-state line MUST be absent on the populated path.
          expect(
            find.text('No techs available to research'),
            findsNothing,
          );
        },
      );

      testWidgets(
        'AC (positive) ChooseTechDialog (empty state) @ 320×640: no '
        'RenderFlex overflow exception, the muted "No techs available to '
        'research" line + Close render — pins the empty-state branch '
        'fitting within the ~288 dp content width.',
        (WidgetTester tester) async {
          await _pumpDialog(
            tester,
            ChooseTechDialog(
              slotIndex: 2,
              availableTechs: const <TechDefinition>[],
              onSelect: (_) {},
            ),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
          // 1-based slot label flips to Slot 3 for slotIndex 2.
          expect(find.text('Choose Tech \u2014 Slot 3'), findsOneWidget);
          expect(
            find.text('No techs available to research'),
            findsOneWidget,
          );
          expect(find.text('Close'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: ChooseTechDialog (3 longest-name techs) @ '
        '1024×768 also pumps without exception (regression sentinel for '
        'the overflow contract — keeps the 320 dp positive pins '
        'meaningful).',
        (WidgetTester tester) async {
          final techs = _longestNamedTechs();

          await _pumpDialog(
            tester,
            ChooseTechDialog(
              slotIndex: 0,
              availableTechs: techs,
              onSelect: (_) {},
            ),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Choose Tech \u2014 Slot 1'), findsOneWidget);
          expect(find.text('Close'), findsOneWidget);
        },
      );
    },
  );
}
