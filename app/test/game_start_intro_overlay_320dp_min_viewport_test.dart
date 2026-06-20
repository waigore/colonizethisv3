// Pin the 320 dp minimum-viewport contract for [GameStartIntroOverlay]
// (OVL10001) — sibling to
// `overture_dialogue_overlay_320dp_min_viewport_test.dart`,
// `intervention_dialogue_overlay_320dp_min_viewport_test.dart`, and
// `call_to_arms_dialogue_overlay_320dp_min_viewport_test.dart` so each
// dialogue overlay's pin lives in a focused file and the host
// `dialogs_320dp_min_viewport_test.dart` stays under the
// `repo.dart_file_non_comment_line_size` 1000 non-comment-line budget
// (`SPEC/program/repo-lint.md`).
//
// `GameStartIntroOverlay` is the blocking new-game intro overlay shown
// the first time the human-controlled GP enters a game session
// (`SPEC/ui/game-start-intro-overlay.md` § Trigger conditions). It wraps
// a [CtFullScreenDialogueShell] (scrim + centered shell at the canonical
// `maxWidth: 520`) around a [CtDialogShell] body; at
// `kMinViewportWidth` (320 dp) the outer `Dialog.insetPadding` (16 dp
// each side) dominates the configured `maxWidth`, collapsing the shell
// to ~288 dp content width — the same budget as the simpler shells
// pinned in `dialogs_320dp_min_viewport_test.dart`.
//
// Per `SPEC/ui/game-start-intro-overlay.md` § States and variants,
// every non-dismissed state of the overlay (loading, presenting-line,
// presenting-choice, transient between Jenny events, error) composes
// its body inside the same `CtFullScreenDialogueShell` scaffold above
// the same title + `CtBrassDivider` chrome header. The error / degraded
// path is the simplest deterministic state that still exercises the
// chrome contract end-to-end in a widget test — `dialogue_acceptance_test.dart`
// already uses a failing `AssetBundle` to force the degraded panel, so
// this narrow-viewport pin reuses the same fast-path through the
// shell rather than depending on the production Yarn asset.
//
// The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the
//    other `*_320dp_min_viewport_test.dart` files rely on.
//  * The localized title `gameStartIntroOverlay_title` ("A New World
//    Awaits") and `CtBrassDivider` chrome anchors render so the
//    canonical [CtFullScreenDialogueShell] header band wraps within
//    the ~288 dp content column.
//  * The localized degraded-path body labels (load-error sentinel +
//    `Continue` action) still render end-to-end so the layout
//    actually exercises the overlay body at 320 dp rather than
//    no-op'ing.
//  * A wide negative control at 1024 × 768 dp pumps without
//    exception against the same fixture so a regression in the host
//    overflow contract upstream of the overlay itself would be
//    caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/game-start-intro-overlay.md` § Acceptance Criteria —
//       § 320 dp viewport pin.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimum supported viewport dimensions for `SPEC/ui/mobile-adaptation.md`
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same overlay renders its default layout. Mirrors
/// the contract used by `dialogs_320dp_min_viewport_test.dart`,
/// `overture_dialogue_overlay_320dp_min_viewport_test.dart`, and
/// `intervention_dialogue_overlay_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// English l10n sentinels for the overlay title + degraded-path body
/// lines. Pinned here so the narrow-pin breaks if those strings change
/// without the SPEC + this contract being refreshed in lockstep
/// (mirrors `app/lib/l10n/arb/app_en.arb`
/// `gameStartIntroOverlay_title`, `game_intro_loadError`, and
/// `game_intervention_continue`).
const String _kOverlayTitle = 'A New World Awaits';
const String _kContinueLabel = 'Continue';
const String _kLoadErrorPrefix = 'Could not load intro dialogue';

/// Asset-bundle stub that always fails the `loadString` call so the
/// overlay routes immediately to the degraded error panel. Mirrors the
/// `_ThrowingAssetBundle` used by `dialogue_acceptance_test.dart` and
/// the `_FailingAssetBundle` used by
/// `intervention_dialogue_overlay_320dp_min_viewport_test.dart` so the
/// narrow-pin reuses the same deterministic fast-path through
/// `CtFullScreenDialogueShell`.
class _FailingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.error(StateError('missing game intro yarn'));
  }
}

/// Pumps [overlay] at [size] under the running editorial-monocle theme.
///
/// Mirrors `_pumpOverlayAtSize` in
/// `intervention_dialogue_overlay_320dp_min_viewport_test.dart` — sets
/// the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so widget code that
/// reads `MediaQuery.sizeOf(context).width` resolves to the same
/// value.
///
/// Embeds [overlay] directly in the Scaffold body rather than driving
/// the real `showDialog` flow because the contract under test is the
/// overlay's own `CtFullScreenDialogueShell` + `CtDialogShell` layout
/// at the narrow viewport, not the barrier / overlay route plumbing
/// (which is already covered by `dialogue_acceptance_test.dart`).
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
  // one for the failed `loadString` future, one for the post-microtask
  // `setState(_loadError = ...)` rebuild that mounts the degraded
  // panel.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — GameStartIntroOverlay @ '
        '320 dp (Refs #2870 S8/S10)',
    () {
      Widget buildOverlay() {
        return GameStartIntroOverlay(
          assetBundle: _FailingAssetBundle(),
          onDismissed: () {},
          child: const SizedBox.expand(),
        );
      }

      testWidgets(
        'AC (positive) GameStartIntroOverlay degraded panel @ '
        '320×640: no RenderFlex overflow exception, "A New World '
        'Awaits" title + CtBrassDivider + load-error body + '
        '"Continue" action label render — the '
        'CtFullScreenDialogueShell scrim + centered CtDialogShell '
        '(maxWidth: 520, dominated by Dialog.insetPadding 16 dp each '
        'side at kMinViewportWidth) collapses to a ~288 dp content '
        'column. The shared `CtFullScreenDialogueShell` chrome (title '
        '+ 12 dp gap + CtBrassDivider + 14 dp gap + per-state body) '
        'MUST wrap within that budget; the degraded body (bodyMedium '
        'load-error text + 16 dp gap + centered Continue '
        'CtNinePatchButton) is the simplest state that still '
        'exercises the column body. Per the overlay\'s § States and '
        'variants (every non-dismissed state composes its body inside '
        'the same CtFullScreenDialogueShell scaffold above the same '
        'title + brass-divider header), this positive pin proves the '
        'chrome contract for every state.',
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
                'GameStartIntroOverlay must not emit a RenderFlex '
                'overflow exception at kMinViewportWidth (320 dp). '
                'The CtFullScreenDialogueShell scrim + centered '
                'CtDialogShell + "A New World Awaits" title + '
                'CtBrassDivider + degraded body must wrap within '
                'the ~288 dp content column.',
          );

          // Title + chrome anchors render via the
          // CtFullScreenDialogueShell scaffold.
          expect(find.text(_kOverlayTitle), findsOneWidget);
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
        'Negative control: GameStartIntroOverlay degraded panel @ '
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
