// Pin the 320 dp minimum-viewport contract for [CallToArmsDialogueOverlay]
// (OVL40001) — extracted from `dialogs_320dp_min_viewport_test.dart` so
// the host file stays under the `repo.dart_file_non_comment_line_size`
// 1000 non-comment-line budget (`SPEC/program/repo-lint.md`).
//
// `CallToArmsDialogueOverlay` is the blocking call-to-arms decision
// overlay shown after turn resolution when a human-controlled ally has
// one or more pending calls. It wraps a [CtDialogShell] inside a
// [CtFullScreenDialogueShell] (scrim + centered shell at
// `maxWidth: 520`, `maxHeight: 500`); at `kMinViewportWidth` (320 dp)
// `Dialog.insetPadding` (16 dp each side) dominates the configured
// `maxWidth`, collapsing the shell to ~288 dp content width — the same
// budget as the simpler shells pinned in
// `dialogs_320dp_min_viewport_test.dart`.
//
// The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the other
//    `*_320dp_min_viewport_test.dart` files rely on.
//  * Dialog body labels (title + Join / Refuse / Submit action labels)
//    still render end-to-end so the layout actually exercises the
//    overlay body at 320 dp rather than no-op'ing.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the host overflow
//    contract upstream of the dialog itself would be caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/call-to-arms-dialogue-overlay.md` § Layout / wireframe.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show CallToArmsPending;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/min_viewport_harness.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same dialog renders its default layout. Mirrors
/// the contract used by `dialogs_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [dialog] at [size] under the running editorial-monocle theme.
///
/// Delegates to the shared `pumpAtMinViewport` harness
/// — which sets the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so dialog code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value.
///
/// Embeds [dialog] directly in the Scaffold body rather than driving the
/// real `showDialog` flow because the contract under test is the
/// dialog's own [CtDialogShell] layout at the narrow viewport, not the
/// barrier / overlay route plumbing (which is already covered by the
/// overlay's own widget tests).
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

  group('SPEC/ui/mobile-adaptation.md § 7 — CallToArmsDialogueOverlay @ '
      '320 dp (Refs #2870 S8/S10)', () {
    // Minimal Game fixture: three GPs so a single pending call can resolve
    // `defenderGpId` / `aggressorGpId` to display names. Mirrors the
    // fixture used by `call_to_arms_dialogue_overlay_dark_chrome_test.dart`
    // so the narrow-pin tests exercise the same name-resolution path as
    // the existing chrome pins.
    Game ctaGame() {
      return const Game(
        id: 'cta_320',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          Player(id: 'gp_player', displayName: 'Player', isHuman: true),
          Player(id: 'gp_portugal', displayName: 'Portugal', isHuman: false),
          Player(id: 'gp_spain', displayName: 'Spain', isHuman: false),
        ],
      );
    }

    const CallToArmsPending singlePendingCall = CallToArmsPending(
      allyGpId: 'gp_player',
      defenderGpId: 'gp_portugal',
      aggressorGpId: 'gp_spain',
    );

    // English l10n sentinels for the title and the three action labels
    // (mirrors `app/lib/l10n/arb/app_en.arb` `game_callToArms_*` keys).
    // Pinned here so the narrow-pin breaks if those strings change without
    // the SPEC + this contract being refreshed in lockstep.
    const String ctaTitle = 'Call to arms';
    const String ctaJoinLabel = 'Join';
    const String ctaRefuseLabel = 'Refuse';
    const String ctaSubmitLabel = 'Submit';

    testWidgets(
      'AC (positive) CallToArmsDialogueOverlay (one pending call) @ '
      '320×640: no RenderFlex overflow exception, "Call to arms" title + '
      'Join / Refuse / Submit action labels render — the per-call '
      'Column(Text + Wrap(Join + Refuse)) stack from '
      'SPEC/ui/call-to-arms-dialogue-overlay.md § Layout / wireframe must '
      'wrap within the ~288 dp CtDialogShell content column at '
      'kMinViewportWidth (CtFullScreenDialogueShell.maxWidth 520 is '
      'dominated by Dialog.insetPadding 16 dp each side at 320 dp)',
      (WidgetTester tester) async {
        await _pumpDialog(
          tester,
          CallToArmsDialogueOverlay(
            game: ctaGame(),
            pending: const [singlePendingCall],
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: CallToArmsDialogueOverlay '
              'must not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The per-call '
              'Column(Text + Wrap(Join + Refuse)) stack under the '
              'CtFullScreenDialogueShell scrim + CtDialogShell chrome '
              'must wrap within the ~288 dp content column.',
        );
        expect(find.text(ctaTitle), findsOneWidget);
        expect(find.text(ctaJoinLabel), findsOneWidget);
        expect(find.text(ctaRefuseLabel), findsOneWidget);
        expect(find.text(ctaSubmitLabel), findsOneWidget);
      },
    );

    testWidgets(
      'AC (positive) CallToArmsDialogueOverlay (two pending calls) @ '
      '320×640: no RenderFlex overflow exception, both Join + Refuse '
      'rows mount within the ~288 dp content column (the ListView.builder '
      'shrink-wrapped body from SPEC/ui/call-to-arms-dialogue-overlay.md '
      '§ Layout / wireframe wraps every per-call Column stack at the '
      'narrow viewport without horizontal overflow)',
      (WidgetTester tester) async {
        const CallToArmsPending secondPendingCall = CallToArmsPending(
          allyGpId: 'gp_player',
          defenderGpId: 'gp_spain',
          aggressorGpId: 'gp_portugal',
        );

        await _pumpDialog(
          tester,
          CallToArmsDialogueOverlay(
            game: ctaGame(),
            pending: const [singlePendingCall, secondPendingCall],
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
          size: _kMinViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(ctaTitle), findsOneWidget);
        // Two rows -> two Join buttons + two Refuse buttons + one Submit
        // action (the Submit button label is shared across the row count).
        expect(find.text(ctaJoinLabel), findsNWidgets(2));
        expect(find.text(ctaRefuseLabel), findsNWidgets(2));
        expect(find.text(ctaSubmitLabel), findsOneWidget);
      },
    );

    testWidgets(
      'Negative control: CallToArmsDialogueOverlay @ 1024×768 also pumps '
      'without exception (regression sentinel for the overflow contract — '
      'keeps the 320 dp positive pins meaningful)',
      (WidgetTester tester) async {
        await _pumpDialog(
          tester,
          CallToArmsDialogueOverlay(
            game: ctaGame(),
            pending: const [singlePendingCall],
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
          size: _kWideRegressionViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(ctaTitle), findsOneWidget);
        expect(find.text(ctaJoinLabel), findsOneWidget);
        expect(find.text(ctaRefuseLabel), findsOneWidget);
        expect(find.text(ctaSubmitLabel), findsOneWidget);
      },
    );
  });
}
