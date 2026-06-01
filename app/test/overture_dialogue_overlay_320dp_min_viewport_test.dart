// Pin the 320 dp minimum-viewport contract for [OvertureDialogueOverlay]
// (OVL30001) — sibling to
// `call_to_arms_dialogue_overlay_320dp_min_viewport_test.dart` so each
// dialogue overlay's pin lives in a focused file and the host
// `dialogs_320dp_min_viewport_test.dart` stays under the
// `repo.dart_file_non_comment_line_size` 1000 non-comment-line budget
// (`SPEC/program/repo-lint.md`).
//
// `OvertureDialogueOverlay` is the blocking overture-acceptance overlay
// shown after turn resolution when one or more pending overtures target
// the human-controlled faction. It wraps a [CtDialogShell] inside a
// [CtFullScreenDialogueShell] (scrim + centered shell at
// `maxWidth: 520`, phase-2 `maxHeight: 500`); at `kMinViewportWidth`
// (320 dp) the outer `Dialog.insetPadding` (16 dp each side) dominates
// the configured `maxWidth`, collapsing the shell to ~288 dp content
// width — the same budget as the simpler shells pinned in
// `dialogs_320dp_min_viewport_test.dart`.
//
// The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the other
//    `*_320dp_min_viewport_test.dart` files rely on.
//  * Phase-2 body labels (title + Accept / Reject / Submit action labels)
//    still render end-to-end so the layout actually exercises the
//    overlay body at 320 dp rather than no-op'ing.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the host overflow
//    contract upstream of the dialog itself would be caught.
//
// The fixture uses `skipIntroForTest: true` so the test does not depend
// on the production `kDialogueOvertureAsset` Yarn bundle — mirroring
// `overture_dialogue_overlay_test.dart` and the Widgetbook story.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/overture-dialogue-overlay.md` § Layout / wireframe + AC
// 320 dp pin.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show OvertureOffer;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
/// Mirrors `_pumpDialogAtSize` in
/// `call_to_arms_dialogue_overlay_320dp_min_viewport_test.dart` — sets
/// the surface size (so the binding's render flex math sees the minimum
/// viewport) and overrides MediaQuery so dialog code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value.
///
/// Embeds [dialog] directly in the Scaffold body rather than driving
/// the real `showDialog` flow because the contract under test is the
/// overlay's own [CtDialogShell] layout at the narrow viewport, not the
/// barrier / overlay route plumbing (which is already covered by the
/// overlay's own widget tests).
Future<void> _pumpDialogAtSize(
  WidgetTester tester,
  Widget dialog, {
  required Size size,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: Center(child: dialog)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — OvertureDialogueOverlay @ '
      '320 dp (Refs #2870 S8/S10)', () {
    // Minimal Game fixture: three GPs so the `_offererDisplayName`
    // lookup in phase-2 resolves `gp_portugal` / `gp_spain` to display
    // names (mirrors the fixture used by
    // `overture_dialogue_overlay_test.dart` so the narrow-pin tests
    // exercise the same name-resolution path as the existing chrome
    // pins).
    Game overtureGame() {
      return const Game(
        id: 'overture_320',
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

    const OvertureOffer singleOffer = OvertureOffer(
      offererGpId: 'gp_portugal',
      targetFactionId: 'gp_player',
      stage: OvertureStage.tradeConsulate,
    );

    const OvertureOffer secondOffer = OvertureOffer(
      offererGpId: 'gp_spain',
      targetFactionId: 'gp_player',
      stage: OvertureStage.embassy,
    );

    // English l10n sentinels for the phase-2 title and the three action
    // labels (mirrors `app/lib/l10n/arb/app_en.arb` `game_overture_*` and
    // `game_callToArms_submit` keys). Pinned here so the narrow-pin
    // breaks if those strings change without the SPEC + this contract
    // being refreshed in lockstep.
    const String overtureTitle = 'Diplomatic overtures';
    const String overtureAcceptLabel = 'Accept';
    const String overtureRejectLabel = 'Reject';
    const String overtureSubmitLabel = 'Submit';

    testWidgets(
      'AC (positive) OvertureDialogueOverlay (one pending offer) @ '
      '320×640: no RenderFlex overflow exception, "Diplomatic overtures" '
      'title + Accept / Reject / Submit action labels render — the '
      'phase-2 Column(Row(offerer + ": " + stage) + Wrap(Accept + '
      'Reject)) from SPEC/ui/overture-dialogue-overlay.md § Layout / '
      'wireframe must wrap within the ~288 dp CtDialogShell content '
      'column at kMinViewportWidth (CtFullScreenDialogueShell.maxWidth '
      '520 is dominated by Dialog.insetPadding 16 dp each side at '
      '320 dp; the Accept + Reject CtNinePatchButtons flow onto a '
      'second Wrap run rather than overflowing horizontally).',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          OvertureDialogueOverlay(
            game: overtureGame(),
            pendingOvertures: const [singleOffer],
            skipIntroForTest: true,
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: OvertureDialogueOverlay '
              'must not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The per-offer Column(Row('
              'offerer + ": " + stage) + Wrap(Accept + Reject)) under '
              'the CtFullScreenDialogueShell scrim + CtDialogShell '
              'chrome must wrap within the ~288 dp content column.',
        );
        expect(find.text(overtureTitle), findsOneWidget);
        expect(find.text(overtureAcceptLabel), findsOneWidget);
        expect(find.text(overtureRejectLabel), findsOneWidget);
        expect(find.text(overtureSubmitLabel), findsOneWidget);
      },
    );

    testWidgets(
      'AC (positive) OvertureDialogueOverlay (two pending offers) @ '
      '320×640: no RenderFlex overflow exception, both Accept + Reject '
      'rows mount within the ~288 dp content column (the '
      'ListView.builder shrink-wrapped body from '
      'SPEC/ui/overture-dialogue-overlay.md § Layout / wireframe stacks '
      'each per-offer Column(Row + Wrap) body at the narrow viewport '
      'without horizontal overflow).',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          OvertureDialogueOverlay(
            game: overtureGame(),
            pendingOvertures: const [singleOffer, secondOffer],
            skipIntroForTest: true,
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
          size: _kMinViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(overtureTitle), findsOneWidget);
        // Two rows -> two Accept buttons + two Reject buttons + one
        // Submit action (the Submit button label is shared across the
        // row count, mirroring the call-to-arms 320 dp pin contract).
        expect(find.text(overtureAcceptLabel), findsNWidgets(2));
        expect(find.text(overtureRejectLabel), findsNWidgets(2));
        expect(find.text(overtureSubmitLabel), findsOneWidget);
      },
    );

    testWidgets(
      'Negative control: OvertureDialogueOverlay @ 1024×768 also pumps '
      'without exception (regression sentinel for the overflow contract '
      '— keeps the 320 dp positive pins meaningful).',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          OvertureDialogueOverlay(
            game: overtureGame(),
            pendingOvertures: const [singleOffer],
            skipIntroForTest: true,
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
          size: _kWideRegressionViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(overtureTitle), findsOneWidget);
        expect(find.text(overtureAcceptLabel), findsOneWidget);
        expect(find.text(overtureRejectLabel), findsOneWidget);
        expect(find.text(overtureSubmitLabel), findsOneWidget);
      },
    );
  });
}
