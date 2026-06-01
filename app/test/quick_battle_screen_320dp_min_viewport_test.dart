// Pin the 320 dp minimum-viewport contract for the `QuickBattleScreen`
// (CMPT20001) tactical mini-game screen — extending the existing screen-,
// panel-, dialog-, and unit-panel-level pins
// (`mobile_320dp_min_viewport_test.dart`, `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`,
// `trade_screen_320dp_min_viewport_test.dart`,
// `technology_screen_320dp_min_viewport_test.dart`,
// `diplomacy_detail_screen_320dp_min_viewport_test.dart`) to the in-game
// Quick Battle screen surfaced when the player picks Quick Battle from
// `CombatModeChoiceDialog` or when a capital siege forces it.
//
// `QuickBattleScreen` (`app/lib/features/game/combat/quick_battle_screen.dart`)
// mounts its chrome via [CtDialogShell] with `maxWidth: 400` and
// `maxHeight: 500`. At `kMinViewportWidth` (320 dp) the outer
// `Dialog.insetPadding: 16` dominates the configured `maxWidth`, so the
// available content area collapses to ~288 dp. Both the round phase
// (round-counter `Text` + `QuickBattleDeploymentView` `CtPanel` + `Wrap`
// of lane/line rows + either the `QuickBattleActionSelector` `Wrap` of
// five `CtNinePatchButton` chips or the single `Resolve (Auto)` button)
// and the result phase (`Battle Result: …` title + optional captured
// banner + two casualty rows + trailing right-aligned `Continue` action)
// must still lay out without `RenderFlex` overflow per the SPEC ACs
// (`SPEC/ui/mobile-adaptation.md` § 7 and
// `SPEC/ui/quick-battle-screen.md` § Acceptance Criteria).
//
// Each positive test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`)
//    escapes the framework — the contract every other
//    `*_320dp_min_viewport_test.dart` file relies on.
//  * Each label the SPEC layout / wireframe declares for the rendered
//    phase is present in the widget tree.
//  * The fallback affordance for the opposite phase is not mounted (the
//    interactive path mounts the action `Wrap` but not `Resolve (Auto)`;
//    the non-interactive path auto-resolves on `initState` so the result
//    view replaces both the round-counter and the auto-resolve button).
//
// The wide negative control at 1024 × 768 dp pumps the non-interactive
// variant against the same fixture so a regression in the host overflow
// contract upstream of `QuickBattleScreen` itself would still surface.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/quick-battle-screen.md` § Layout / wireframe and
// § Acceptance Criteria (320 dp positive + wide regression pins).
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_screen.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, dialog-, and unit-panel-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same screen renders its default chrome. Mirrors
/// the contract used by `mobile_320dp_min_viewport_test.dart`,
/// `panels_320dp_min_viewport_test.dart`,
/// `dialogs_320dp_min_viewport_test.dart`,
/// `unit_panels_320dp_min_viewport_test.dart`,
/// `trade_screen_320dp_min_viewport_test.dart`, and
/// `diplomacy_detail_screen_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Minimal two-faction Quick Battle input matching the existing
/// `quick_battle_screen_test.dart` fixture (one CENTER + FRONT group per
/// side, `maxRounds = 3`). The 2 vs 1 unit count keeps the resolver
/// output deterministic enough that the "Battle Result: …" winner
/// sentence and both casualty rows must render in the result view.
QuickBattleInput _input() {
  return const QuickBattleInput(
    attackerFactionId: 'gp1',
    defenderFactionId: 'gp2',
    attackerDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: ['a1', 'a2'],
          cohesion: 3,
        ),
      ],
    ),
    defenderDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: ['d1'],
          cohesion: 3,
        ),
      ],
    ),
    provinceId: 'oldWorld|p1',
    regionId: 'oldWorld',
    maxRounds: 3,
  );
}

/// Pumps the [QuickBattleScreen] at [size] under the running
/// editorial-monocle theme. Sets the surface size (so the binding's
/// render-flex math sees the minimum viewport) and overrides MediaQuery
/// so widget code that reads `MediaQuery.sizeOf(context).width` resolves
/// to the same value — the pattern already used by every other
/// `*_320dp_min_viewport_test.dart` file.
///
/// Wraps the screen in `Scaffold(body: Center(child: ...))` mirroring
/// the helper used by `quick_battle_screen_test.dart` so the chrome
/// under test is the screen's own [CtDialogShell] layout at the narrow
/// viewport, not the barrier / overlay route plumbing (which is already
/// covered by other tests).
Future<void> _pumpQuickBattleScreenAtSize(
  WidgetTester tester, {
  required Size size,
  required bool interactive,
  ValueChanged<QuickBattleResult>? onComplete,
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
        child: Scaffold(
          body: Center(
            child: QuickBattleScreen(
              input: _input(),
              onComplete: onComplete ?? (_) {},
              interactive: interactive,
            ),
          ),
        ),
      ),
    ),
  );
  // A single extra pump settles the `setState` scheduled from
  // `initState` on the non-interactive auto-resolve path. The
  // interactive path also pumps once so the action `Wrap` lays out
  // against the actual viewport.
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — QuickBattleScreen non-interactive '
    '(result view) @ 320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) QuickBattleScreen interactive: false @ 320×640: no '
        'RenderFlex overflow exception, Battle Result winner sentence + '
        'both casualty rows + Continue render',
        (WidgetTester tester) async {
          await _pumpQuickBattleScreenAtSize(
            tester,
            size: _kMinViewport,
            interactive: false,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: QuickBattleScreen '
                '(interactive: false, result view after auto-resolve) '
                'MUST NOT emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The result view from '
                'SPEC/ui/quick-battle-screen.md § Result phase auto-runs '
                'through resolveQuickBattle in initState and MUST lay '
                'out the Battle Result winner title + optional captured '
                'banner + two casualty bodySmall rows + trailing '
                'right-aligned Continue action within the ~288 dp '
                'CtDialogShell content column.',
          );

          // The "Battle Result: <winner>" title resolves through
          // `l10n.quickBattle_battleResult(...)` and renders regardless
          // of which side wins under the 2 vs 1 fixture above.
          expect(find.textContaining('Battle Result:'), findsOneWidget);

          // Both per-side casualty rows render via
          // `l10n.quickBattle_casualties(name, count)` so the
          // bodySmall casualty lines actually lay out at narrow widths.
          expect(find.textContaining('Attacker casualties:'), findsOneWidget);
          expect(find.textContaining('Defender casualties:'), findsOneWidget);

          // Trailing right-aligned Continue action MUST remain
          // reachable at 320 dp so the orchestrator can drive
          // `onComplete` once the user dismisses the result view.
          expect(find.text('Continue'), findsOneWidget);

          // The round-counter title and Resolve (Auto) fallback MUST
          // both be absent in the result view: the screen replaces
          // the round-phase column with the `_ResultView` widget once
          // `_result != null`. The absence here is the negative AC
          // that proves the non-interactive auto-resolve path
          // transitioned out of the round phase.
          expect(find.textContaining('Quick Battle — Round'), findsNothing);
          expect(find.text('Resolve (Auto)'), findsNothing);
        },
      );

      testWidgets(
        'AC (positive) QuickBattleScreen interactive: false @ 320×640: '
        'tapping Continue invokes onComplete exactly once with the '
        'resolver result (the trailing right-aligned CtNinePatchButton '
        'is still reachable at the minimum viewport)',
        (WidgetTester tester) async {
          int completeCount = 0;
          QuickBattleResult? lastResult;
          await _pumpQuickBattleScreenAtSize(
            tester,
            size: _kMinViewport,
            interactive: false,
            onComplete: (r) {
              completeCount += 1;
              lastResult = r;
            },
          );

          // The Continue button MUST be hit-testable inside the ~288 dp
          // CtDialogShell content column at 320 dp.
          await tester.tap(find.text('Continue'));
          await tester.pump();

          expect(
            completeCount,
            1,
            reason:
                'SPEC/ui/quick-battle-screen.md § Acceptance Criteria: '
                'tapping Continue MUST invoke onComplete exactly once '
                'and the Continue button MUST remain reachable at '
                'kMinViewportWidth (320 dp) so the narrow viewport '
                'does not break the result-view dismissal contract.',
          );
          expect(lastResult, isNotNull);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — QuickBattleScreen interactive '
    '(round phase) @ 320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) QuickBattleScreen interactive: true @ 320×640: no '
        'RenderFlex overflow exception, round-counter title + '
        'QuickBattleActionSelector Command Points header + every action '
        'Wrap child render, and the Resolve (Auto) fallback is absent',
        (WidgetTester tester) async {
          await _pumpQuickBattleScreenAtSize(
            tester,
            size: _kMinViewport,
            interactive: true,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: QuickBattleScreen '
                '(interactive: true, round phase) MUST NOT emit a '
                'RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). The round-counter Text, the '
                'QuickBattleDeploymentView CtPanel + Wrap of lane/line '
                'rows, and the QuickBattleActionSelector Wrap of five '
                'CtNinePatchButton chips (Volley Fire / Defend / '
                'Maneuver / Fall Back / Assault) MUST lay out within '
                'the ~288 dp CtDialogShell content column without '
                'horizontal overflow — the action chips MUST flow onto '
                'extra runs rather than overflowing the row.',
          );

          // Round-counter title resolves to `Quick Battle — Round 1 / 3`
          // per `l10n.quickBattle_round(1, 3)` and the fixture's
          // `maxRounds = 3`.
          expect(
            find.textContaining('Quick Battle — Round 1 / 3'),
            findsOneWidget,
          );

          // QuickBattleActionSelector header from
          // `l10n.quickBattle_commandPoints(3)` MUST render so the
          // Wrap of action chips is actually exercised at narrow
          // widths.
          expect(find.textContaining('Command Points: 3'), findsOneWidget);

          // Every action chip from SPEC/ui/quick-battle-screen.md
          // § Layout / wireframe — Round phase MUST mount at 320 dp
          // (label rendered via `l10n.quickBattle_actionWithCost(...)`
          // so `find.textContaining` matches the label fragment
          // before the CP suffix).
          expect(find.textContaining('Volley Fire'), findsOneWidget);
          expect(find.textContaining('Defend'), findsOneWidget);
          expect(find.textContaining('Maneuver'), findsOneWidget);
          expect(find.textContaining('Fall Back'), findsOneWidget);
          expect(find.textContaining('Assault'), findsOneWidget);

          // Non-interactive fallback button MUST be absent so the
          // interactive branch from SPEC § States and variants is
          // actually exercised (negative AC).
          expect(find.text('Resolve (Auto)'), findsNothing);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — QuickBattleScreen wide '
    'regression sentinel (Refs #2870 S10)',
    () {
      testWidgets(
        'Negative control: QuickBattleScreen interactive: false @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the overflow contract — keeps the 320 dp positive pins '
        'meaningful)',
        (WidgetTester tester) async {
          await _pumpQuickBattleScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
            interactive: false,
          );

          expect(tester.takeException(), isNull);
          expect(find.textContaining('Battle Result:'), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);
        },
      );
    },
  );
}
