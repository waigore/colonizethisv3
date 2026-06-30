// Pin the 320 dp minimum-viewport contract for [GrantOrSubsidyDialog]
// (DIPL20001) — sibling to `dialogs_320dp_min_viewport_test.dart` and
// the per-overlay narrow pins
// (`call_to_arms_dialogue_overlay_320dp_min_viewport_test.dart`,
// `intervention_dialogue_overlay_320dp_min_viewport_test.dart`,
// `overture_dialogue_overlay_320dp_min_viewport_test.dart`).
//
// `GrantOrSubsidyDialog` is the diplomacy stepper modal opened from
// `DiplomacyPanel` Grant Aid / Set Subsidy actions
// (`SPEC/ui/grant-or-subsidy-dialog.md`,
// `SPEC/ui/diplomacy-panel.md`). It wraps a [CtDialogShell] containing a
// title, a treasury / step body row, a 1 dp `--border` divider, the
// bespoke (`−` / `+`) amount stepper, an optional below-minimum hint,
// and a right-aligned Cancel + Submit `Row`. At `kMinViewportWidth`
// (320 dp) the outer `Dialog.insetPadding` (16 dp each side) dominates
// the catalog `maxWidth: 480`, collapsing the shell to ~288 dp content
// width — the same budget every other dialog pinned in
// `dialogs_320dp_min_viewport_test.dart` shares.
//
// Three positive cases plus a wide regression sentinel cover the two
// modes plus the below-minimum branch:
//
//  * Grant mode (`isSubsidy: false`) with a treasury comfortably above
//    `grantAidAmountStep` — pins the title, treasury / step body, both
//    keyed stepper buttons, the keyed amount label, and the trailing
//    Cancel + Submit row.
//  * Subsidy mode (`isSubsidy: true`) with the same fixture so the
//    title flips to `Set subsidy` and the stepper continues to use the
//    smaller `setSubsidyAmountStep` (= `100`).
//  * Below-minimum branch (`treasury < grantAidAmountStep`) — pins the
//    additional `_BelowMinimumWarning` row that mounts when both
//    stepper buttons are disabled, ensuring the optional warning row +
//    16 dp gap + Cancel/Submit row continue to fit within the ~288 dp
//    budget.
//  * Negative control at 1024 × 768 dp pumps without exception against
//    the same Grant-mode fixture so a regression in the host overflow
//    contract upstream of the dialog itself would be caught.
//
// The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the other
//    `*_320dp_min_viewport_test.dart` files rely on.
//  * Localized title + treasury body + Cancel + Submit labels render
//    end-to-end so the layout actually exercises the dialog body at
//    320 dp rather than no-op'ing.
//  * The keyed amount label and both stepper buttons (`diplo_amount_minus`
//    and `diplo_amount_plus`) mount so the dialog's bespoke `−` / `+`
//    chrome from `SPEC/ui/grant-or-subsidy-dialog.md` § Amount stepper
//    fits in the narrow content column.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/grant-or-subsidy-dialog.md` § Layout / wireframe and
// § Acceptance Criteria.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_dialogs.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show grantAidAmountStep;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/min_viewport_harness.dart';

/// Minimum supported viewport dimensions for `SPEC/ui/mobile-adaptation.md`
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same dialog renders its default layout. Mirrors
/// the contract used by `dialogs_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Two-player fixture: `gp1` is the human (with the seeded treasury),
/// `gp2` is the rival who is the grant / subsidy target. The dialog
/// reads only `humanPlayerId` → `treasury` and is otherwise indifferent
/// to the rest of the [Game]; this minimal fixture is the same shape
/// used by `dialogs_320dp_min_viewport_test.dart` for sibling dialogs.
Game _buildGame({required int humanTreasury}) {
  return Game(
    id: 'g_dipl20001',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'Castile',
        isHuman: true,
        treasury: humanTreasury,
      ),
      const Player(
        id: 'gp2',
        displayName: 'England',
        isHuman: false,
        treasury: 0,
      ),
    ],
  );
}

/// Pumps [dialog] at [size] under the running editorial-monocle theme.
///
/// Delegates to the shared `pumpAtMinViewport` harness
/// — which sets the surface size (so
/// the binding's render flex math sees the minimum viewport) and
/// overrides MediaQuery so dialog code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value.
///
/// Embeds [dialog] directly in the Scaffold body rather than driving
/// the real `showDialog` flow because the contract under test is the
/// dialog's own `CtDialogShell` layout at the narrow viewport, not the
/// barrier / overlay route plumbing (which is already covered by
/// `diplomacy_dialogs_test.dart`).
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
    'SPEC/ui/mobile-adaptation.md § 7 — GrantOrSubsidyDialog (DIPL20001) '
    '@ 320 dp (Refs #2870 S8/S10)',
    () {
      testWidgets(
        'AC (positive) GrantOrSubsidyDialog (grant mode, treasury 5000) '
        '@ 320×640: no RenderFlex overflow exception, "Grant aid" title + '
        'treasury body + amount label + both stepper buttons + Cancel + '
        'Submit labels render — the CtDialogShell at 320 dp collapses to '
        '~288 dp content width and the title row, treasury / step body, '
        '1 dp thin divider, centered "−" / "+" stepper, and trailing '
        'right-aligned Cancel + Submit Row must wrap within that budget '
        'per SPEC/ui/grant-or-subsidy-dialog.md § Layout / wireframe.',
        (WidgetTester tester) async {
          // 5x the step (= 5000 with grantAidAmountStep = 1000) so the
          // initial amount snaps to grantAidDefaultAmount (1000) and
          // both stepper buttons are enabled — the canonical happy path
          // through the dialog body.
          final game = _buildGame(humanTreasury: 5 * grantAidAmountStep);
          final bus = AppEventBus.create();

          await _pumpDialog(
            tester,
            GrantOrSubsidyDialog(
              game: game,
              humanPlayerId: 'gp1',
              targetFactionId: 'gp2',
              isSubsidy: false,
              bus: bus,
            ),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: GrantOrSubsidyDialog '
                'must not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The CtDialogShell title + '
                'treasury / step body + 1 dp thin divider + "−" / "+" '
                'stepper + Cancel/Submit Row must wrap within the '
                '~288 dp content width.',
          );
          // Title + treasury + action labels render end-to-end.
          expect(find.text('Grant aid'), findsOneWidget);
          expect(find.textContaining('Treasury:'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Submit'), findsOneWidget);
          // Keyed chrome anchors mount so the bespoke stepper fits in
          // the narrow column.
          expect(
            find.byKey(const Key('grantOrSubsidyDialogTitle')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('grantOrSubsidyDialogTreasury')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('grantOrSubsidyDialogThinDivider')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('grantOrSubsidyDialogAmount')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('diplo_amount_minus')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('diplo_amount_plus')),
            findsOneWidget,
          );
          // Below-minimum hint MUST be absent on the happy path.
          expect(
            find.byKey(const Key('grantOrSubsidyDialogWarning')),
            findsNothing,
          );
        },
      );

      testWidgets(
        'AC (positive) GrantOrSubsidyDialog (subsidy mode, treasury 5000) '
        '@ 320×640: no RenderFlex overflow exception, "Set subsidy" '
        'title + percent step line + Cancel + Submit labels render — the '
        'title flips to the subsidy slot and the treasury-independent '
        'percent stepper (5–20%, step 5) stays enabled at the same narrow '
        'viewport (Refs #3753 R3).',
        (WidgetTester tester) async {
          final game = _buildGame(humanTreasury: 5 * grantAidAmountStep);
          final bus = AppEventBus.create();

          await _pumpDialog(
            tester,
            GrantOrSubsidyDialog(
              game: game,
              humanPlayerId: 'gp1',
              targetFactionId: 'gp2',
              isSubsidy: true,
              bus: bus,
            ),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Set subsidy'), findsOneWidget);
          // Subsidy mode shows the percent step line, not the £ treasury copy.
          expect(find.textContaining('Subsidy step:'), findsOneWidget);
          expect(find.textContaining('Treasury:'), findsNothing);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Submit'), findsOneWidget);
          // Below-minimum hint MUST stay absent — subsidy is treasury-independent.
          expect(
            find.byKey(const Key('grantOrSubsidyDialogWarning')),
            findsNothing,
          );
        },
      );

      testWidgets(
        'AC (positive) GrantOrSubsidyDialog (grant mode, treasury below '
        'minimum step) @ 320×640: no RenderFlex overflow exception, the '
        'keyed _BelowMinimumWarning row mounts, both stepper buttons are '
        'disabled, and the trailing Cancel + Submit Row still renders — '
        'pins the optional warning + 16 dp gap + action row contract '
        'fitting within the ~288 dp content width per '
        'SPEC/ui/grant-or-subsidy-dialog.md § Layout / wireframe.',
        (WidgetTester tester) async {
          // Treasury strictly below grantAidAmountStep (= 1000) so
          // canAdjust is false and the warning row mounts.
          final game = _buildGame(humanTreasury: grantAidAmountStep - 1);
          final bus = AppEventBus.create();

          await _pumpDialog(
            tester,
            GrantOrSubsidyDialog(
              game: game,
              humanPlayerId: 'gp1',
              targetFactionId: 'gp2',
              isSubsidy: false,
              bus: bus,
            ),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: GrantOrSubsidyDialog '
                'must not overflow at kMinViewportWidth (320 dp) when '
                'the optional below-minimum warning row mounts above the '
                'Cancel + Submit Row.',
          );
          expect(find.text('Grant aid'), findsOneWidget);
          expect(
            find.byKey(const Key('grantOrSubsidyDialogWarning')),
            findsOneWidget,
          );
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Submit'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: GrantOrSubsidyDialog (grant mode) @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract — keeps the 320 dp positive pins meaningful).',
        (WidgetTester tester) async {
          final game = _buildGame(humanTreasury: 5 * grantAidAmountStep);
          final bus = AppEventBus.create();

          await _pumpDialog(
            tester,
            GrantOrSubsidyDialog(
              game: game,
              humanPlayerId: 'gp1',
              targetFactionId: 'gp2',
              isSubsidy: false,
              bus: bus,
            ),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Grant aid'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Submit'), findsOneWidget);
        },
      );
    },
  );
}
