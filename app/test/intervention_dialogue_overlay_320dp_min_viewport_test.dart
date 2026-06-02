// Pin the 320 dp minimum-viewport contract for [InterventionDialogueOverlay]
// (OVL50001) — sibling to
// `overture_dialogue_overlay_320dp_min_viewport_test.dart` and
// `call_to_arms_dialogue_overlay_320dp_min_viewport_test.dart` so each
// dialogue overlay's pin lives in a focused file and the host
// `dialogs_320dp_min_viewport_test.dart` stays under the
// `repo.dart_file_non_comment_line_size` 1000 non-comment-line budget
// (`SPEC/program/repo-lint.md`).
//
// `InterventionDialogueOverlay` is the blocking pending-intervention
// overlay shown after turn resolution when the human-controlled GP
// must adjudicate one or more `InterventionPrompt` rows. It wraps a
// [CtDialogShell] inside a [CtFullScreenDialogueShell] (scrim +
// centered shell at `maxWidth: 520`); at `kMinViewportWidth` (320 dp)
// the outer `Dialog.insetPadding` (16 dp each side) dominates the
// configured `maxWidth`, collapsing the shell to ~288 dp content
// width — the same budget as the simpler shells pinned in
// `dialogs_320dp_min_viewport_test.dart`.
//
// Per the dark editorial-monocle chrome contract pinned by
// `intervention_dialogue_overlay_dark_chrome_test.dart` and
// `SPEC/ui/screens/pending-intervention-overlay.md` § Dark
// editorial-monocle chrome, every phase of the overlay (Yarn loading,
// Yarn line, Yarn choice, situation, choice picker, reaction, and the
// degraded error fallback) routes through the same private
// `_buildScrimmedShell` helper. Pinning the degraded fallback at
// 320 dp therefore proves the chrome contract for every phase: the
// scrim, title + brass-divider header, body padding, and trailing
// `CtNinePatchButton` action are produced by that single helper. The
// choice-picker and Yarn-active phases require a fully-loaded Yarn
// project and an async `DialogueRunner`, which the existing dark
// chrome test deliberately avoids exercising in widget tests for the
// same determinism reason — this 320 dp pin follows the same
// approach.
//
// The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the
//    other `*_320dp_min_viewport_test.dart` files rely on.
//  * The localized degraded-path body labels (load-error sentinel +
//    `Continue` action) still render end-to-end so the layout
//    actually exercises the overlay body at 320 dp rather than
//    no-op'ing.
//  * The keyed `Pending Intervention` title and `CtBrassDivider`
//    chrome anchors render so the canonical
//    [CtFullScreenDialogueShell] header band wraps within the
//    ~288 dp content column.
//  * A wide negative control at 1024 × 768 dp pumps without
//    exception against the same fixture so a regression in the host
//    overflow contract upstream of the overlay itself would be
//    caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/screens/pending-intervention-overlay.md` § Dark
// editorial-monocle chrome + § 320 dp viewport pin.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show InterventionPrompt;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimum supported viewport dimensions for `SPEC/ui/mobile-adaptation.md`
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same overlay renders its default layout. Mirrors
/// the contract used by `dialogs_320dp_min_viewport_test.dart` and
/// `overture_dialogue_overlay_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Asset-bundle stub that always fails the `loadString` call so the
/// overlay routes immediately to the degraded error panel. Mirrors the
/// stub used by `intervention_dialogue_overlay_test.dart` and
/// `intervention_dialogue_overlay_dark_chrome_test.dart` so the
/// narrow-pin reuses the same deterministic fast-path through
/// `_buildScrimmedShell`.
class _FailingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.error(StateError('missing intervention yarn'));
  }
}

/// Minimal `Game` fixture mirroring the dark-chrome test fixture so
/// the per-prompt name-resolution path (aggressor / defender /
/// intervening) can resolve `gp1` / `gp2` / `minor1` to display names
/// even though the awaiting-choice phase never renders in widget tests
/// (forced degraded path).
const Game _kFixtureGame = Game(
  id: 'iv_320',
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [
    Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
    Player(id: 'gp2', displayName: 'Aggressor', isHuman: false, treasury: 0),
  ],
  minorNations: [
    MinorNation(id: 'minor1', displayName: 'Minor 1'),
  ],
);

/// One-prompt fixture — the smallest payload that still exercises the
/// per-prompt situation + reaction loop in `_runFlow`. The degraded
/// path consumes `widget.prompts` only on submit; the structure of
/// the list is otherwise irrelevant to the chrome contract.
const List<InterventionPrompt> _kFixturePrompts = [
  InterventionPrompt(
    aggressorGpId: 'gp2',
    defenderMinorOrTribeId: 'minor1',
    interveningGpId: 'gp1',
  ),
];

/// Pumps [overlay] at [size] under the running editorial-monocle theme.
///
/// Mirrors `_pumpDialogAtSize` in
/// `overture_dialogue_overlay_320dp_min_viewport_test.dart` — sets
/// the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so widget code that
/// reads `MediaQuery.sizeOf(context).width` resolves to the same
/// value.
///
/// Embeds [overlay] directly in the Scaffold body rather than driving
/// the real `showDialog` flow because the contract under test is the
/// overlay's own `CtFullScreenDialogueShell` + `CtDialogShell` layout
/// at the narrow viewport, not the barrier / overlay route plumbing
/// (which is already covered by the overlay's own widget tests).
Future<void> _pumpOverlayAtSize(
  WidgetTester tester,
  Widget overlay, {
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
        child: Scaffold(body: Center(child: overlay)),
      ),
    ),
  );
  // Two pumps mirror the existing intervention degraded-path tests:
  // one for the failed `loadString` future, one for the
  // post-microtask `setState(_loadError = ...)` rebuild that mounts
  // the degraded panel.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// English l10n sentinels for the overlay title + degraded body lines
/// + Continue action. Pinned here so the narrow-pin breaks if those
/// strings change without the SPEC + this contract being refreshed in
/// lockstep (mirrors `app/lib/l10n/arb/app_en.arb`
/// `game_intervention_overlayTitle`,
/// `game_intervention_loadError`, and `game_intervention_continue`).
const String _kOverlayTitle = 'Pending Intervention';
const String _kContinueLabel = 'Continue';
const String _kLoadErrorPrefix = 'Could not load intervention dialogue';

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — InterventionDialogueOverlay @ '
        '320 dp (Refs #2870 S8/S10)',
    () {
      Widget buildOverlay() {
        return InterventionDialogueOverlay(
          game: _kFixtureGame,
          prompts: _kFixturePrompts,
          skipIntroForTest: true,
          assetBundle: _FailingAssetBundle(),
          onDecisions: (_) {},
          child: const SizedBox.expand(),
        );
      }

      testWidgets(
        'AC (positive) InterventionDialogueOverlay degraded panel @ '
        '320×640: no RenderFlex overflow exception, "Pending '
        'Intervention" title + brass divider + load-error body + '
        '"Continue" action label render — the '
        'CtFullScreenDialogueShell scrim + centered CtDialogShell '
        '(maxWidth: 520, dominated by Dialog.insetPadding 16 dp each '
        'side at kMinViewportWidth) collapses to a ~288 dp content '
        'column. The shared `_buildScrimmedShell` chrome (title + 8 '
        'dp gap + CtBrassDivider + 12 dp gap + per-phase body) MUST '
        'wrap within that budget; the degraded body (bodyMedium '
        'load-error text + 16 dp gap + bodySmall hint + 16 dp gap + '
        'right-aligned Continue CtNinePatchButton) is the simplest '
        'phase that still exercises the column body. Per the '
        'overlay\'s § Dark editorial-monocle chrome AC (every phase '
        'routes through the same `_buildScrimmedShell` helper), this '
        'positive pin proves the chrome contract for every phase.',
        (WidgetTester tester) async {
          await _pumpOverlayAtSize(
            tester,
            buildOverlay(),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: '
                'InterventionDialogueOverlay must not emit a '
                'RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). The CtFullScreenDialogueShell scrim + '
                'centered CtDialogShell + Pending Intervention '
                'title + CtBrassDivider + degraded body must wrap '
                'within the ~288 dp content column.',
          );

          // Title + chrome anchors render via `_buildScrimmedShell`.
          expect(
            find.byKey(
              const ValueKey<String>(kInterventionOverlayTitleKey),
            ),
            findsOneWidget,
          );
          expect(find.text(_kOverlayTitle), findsOneWidget);
          expect(
            find.byKey(
              const ValueKey<String>(kInterventionOverlayBrassDividerKey),
            ),
            findsOneWidget,
          );
          expect(find.byType(CtBrassDivider), findsOneWidget);

          // Degraded body labels render end-to-end.
          expect(
            find.textContaining(_kLoadErrorPrefix),
            findsOneWidget,
          );
          expect(find.text(_kContinueLabel), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: InterventionDialogueOverlay degraded panel @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the overflow contract — keeps the 320 dp positive pin '
        'meaningful).',
        (WidgetTester tester) async {
          await _pumpOverlayAtSize(
            tester,
            buildOverlay(),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text(_kOverlayTitle), findsOneWidget);
          expect(find.byType(CtBrassDivider), findsOneWidget);
          expect(
            find.textContaining(_kLoadErrorPrefix),
            findsOneWidget,
          );
          expect(find.text(_kContinueLabel), findsOneWidget);
        },
      );
    },
  );
}
