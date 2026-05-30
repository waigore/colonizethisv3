// Pin the 320 dp minimum-viewport contract for the in-game modal dialogs
// that share the [CtDialogShell] chrome — extending the existing screen-
// and panel-level pins (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`) to the simplest in-game dialogs:
//
//  * [GameParametersDialog]            — read-only campaign parameters
//    opened from the hamburger side menu
//    (SPEC/ui/in-game-shell-narrow.md § Game Parameters).
//  * [ExitConfirmDialog]               — Android back exit-to-main-menu
//    confirm (SPEC/ui/in-game-shell-narrow.md § Android back confirm).
//  * [TurnNewsDialog]                  — universal turn-start news modal
//    shown after each turn resolution (SPEC/ui/turn-news-dialog.md).
//  * [GameMapOptionsDialog]            — in-game map display options
//    (toggle overlay / ownership / names) opened from the empire-overview
//    corner controls (SPEC/ui/empire-overview.md § Map display options).
//  * [TurnResolutionProcessingDialog]  — worker-isolate "processing turn"
//    modal raised while the next-turn isolate runs
//    (SPEC/program/turn-resolution.md).
//  * [CombatModeChoiceDialog]            — Auto-Resolve vs Quick Battle picker
//    opened via `OpenDialogEvent('combat_mode_choice')`
//    (SPEC/ui/combat-mode-choice-dialog.md).
//
// All six dialogs render their chrome via [CtDialogShell] (Dialog with
// `insetPadding: 16` and an inner `ConstrainedBox(maxWidth: 400|480)`).
// At `kMinViewportWidth` (320 dp) the available content width collapses
// to ~288 dp, which is the most constrained surface either dialog
// renders against in production. The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the other
//    `*_320dp_min_viewport_test.dart` files rely on.
//  * Dialog body labels (title + action labels) still render end-to-end
//    so the layout actually exercises the dialog body at 320 dp rather
//    than no-op'ing.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixtures so a regression in the host overflow
//    contract upstream of the dialog itself would be caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/in-game-shell-narrow.md` § Game Parameters and
// § Android back confirm.
// SPEC: `SPEC/ui/turn-news-dialog.md` § Layout / wireframe.
// SPEC: `SPEC/ui/empire-overview.md` § Map display options.
// SPEC: `SPEC/program/turn-resolution.md` (Processing-turn modal).
// SPEC: `SPEC/ui/combat-mode-choice-dialog.md`.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/flame/exit_confirm_dialog.dart';
import 'package:colonizethis_app/features/game/flame/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/game_map_options_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/game_parameters_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/turn_news_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen- and panel-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same dialog renders its default layout. Mirrors
/// the contract used by `mobile_320dp_min_viewport_test.dart` and
/// `panels_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [dialog] at [size] under the running editorial-monocle theme.
///
/// Sets the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so dialog code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value — the
/// pattern already used by `mobile_320dp_min_viewport_test.dart` and
/// `victory_overlay_narrow_test.dart`.
///
/// Embeds [dialog] directly in the Scaffold body rather than driving the
/// real `showDialog` flow because the contract under test is the
/// dialog's own [CtDialogShell] layout at the narrow viewport, not the
/// barrier / overlay route plumbing (which is already covered by
/// `exit_confirm_dialog_test.dart`).
Future<void> _pumpDialogAtSize(
  WidgetTester tester,
  Widget dialog, {
  required Size size,
  bool settle = true,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: Center(child: dialog)),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Single frame is enough for dialogs that host an indefinite ticker
    // (e.g. CircularProgressIndicator inside CtLoadingIndicator). The
    // layout has resolved by the first frame, which is all the 320 dp
    // overflow contract needs.
    await tester.pump();
  }
}

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — GameParametersDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) GameParametersDialog (infiniteMode off) @ 320×640: '
      'no RenderFlex overflow exception, title + close action render',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          const GameParametersDialog(infiniteMode: false),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: GameParametersDialog must '
              'not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). CtDialogShell at 320 dp '
              'collapses to ~288 dp content width — title text, the '
              '"Infinite mode: …" line, and the trailing Close action must '
              'all wrap within that.',
        );
        expect(find.text('Game Parameters'), findsOneWidget);
        expect(find.text('Infinite mode: Off'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      },
    );

    testWidgets(
      'AC (positive) GameParametersDialog (infiniteMode on) @ 320×640: '
      'no exception, "Infinite mode: On" body line renders',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          const GameParametersDialog(infiniteMode: true),
          size: _kMinViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Game Parameters'), findsOneWidget);
        expect(find.text('Infinite mode: On'), findsOneWidget);
      },
    );

    testWidgets('Negative control: GameParametersDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pins meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        const GameParametersDialog(infiniteMode: false),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Game Parameters'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — ExitConfirmDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    testWidgets('AC (positive) ExitConfirmDialog @ 320×640: no RenderFlex '
        'overflow exception, title + body + Cancel + Exit all render', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        const ExitConfirmDialog(),
        size: _kMinViewport,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: ExitConfirmDialog must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The Cancel + Exit Row '
            '(end-aligned, two CtNinePatchButtons + an 8 dp gap) must '
            'fit within the ~288 dp content width without overflow.',
      );
      expect(find.text('Exit game?'), findsOneWidget);
      expect(
        find.text('Your current progress will be lost if not saved.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('Negative control: ExitConfirmDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract)', (WidgetTester tester) async {
      await _pumpDialogAtSize(
        tester,
        const ExitConfirmDialog(),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Exit game?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — TurnNewsDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    // Minimal Game fixture: two GPs so populated digest lines can resolve
    // [Game.factionDisplayNameById] for diplomacy + capture lines.
    // Mirrors the fixture used by `turn_news_dialog_test.dart` so the
    // narrow-pin tests exercise the same shaping path as the existing
    // SPEC pins.
    final Game baseGame = Game(
      id: 'g',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
        Player(id: 'gp2', displayName: 'France', isHuman: false, treasury: 0),
      ],
    );

    testWidgets('AC (positive) TurnNewsDialog (empty digest) @ 320×640: no '
        'RenderFlex overflow exception, "Turn 2" title + empty-state '
        'copy + Close action render', (WidgetTester tester) async {
      await _pumpDialogAtSize(
        tester,
        TurnNewsDialog(
          game: baseGame,
          digest: const TurnNewsDigest(
            resolvedTurnNumber: 1,
            lines: <TurnNewsLine>[],
          ),
          newTurnNumber: 2,
        ),
        size: _kMinViewport,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: TurnNewsDialog must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The empty-state path '
            '(title + muted empty-copy + trailing Close action) '
            'must wrap within the ~288 dp content width.',
      );
      expect(find.text('Turn 2'), findsOneWidget);
      expect(find.text('No major events last turn.'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('AC (positive) TurnNewsDialog (populated digest, 3 lines) @ '
        '320×640: no RenderFlex overflow exception, title + each line + '
        'Close render (the ConstrainedBox(maxHeight: 320) ListView body '
        'wraps each line within the ~288 dp content width)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        TurnNewsDialog(
          game: baseGame,
          digest: const TurnNewsDigest(
            resolvedTurnNumber: 1,
            lines: <TurnNewsLine>[
              TurnNewsDiplomacyLine(
                factionIdA: 'gp1',
                factionIdB: 'gp2',
                kind: TurnNewsDiplomacyKind.war,
              ),
              TurnNewsDiplomacyLine(
                factionIdA: 'gp1',
                factionIdB: 'gp2',
                kind: TurnNewsDiplomacyKind.peace,
              ),
              TurnNewsOvertureAdvancedLine(
                offererGpId: 'gp1',
                targetFactionId: 'gp2',
                newStage: OvertureStage.nap,
              ),
            ],
          ),
          newTurnNumber: 2,
        ),
        size: _kMinViewport,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: TurnNewsDialog must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp) with multiple digest lines. '
            'The ConstrainedBox(maxHeight: 320) ListView body must '
            'wrap each line text within the ~288 dp content width '
            'without horizontal overflow.',
      );
      expect(find.text('Turn 2'), findsOneWidget);
      expect(find.text('England and France are now at war.'), findsOneWidget);
      expect(find.text('England and France are now at peace.'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Negative control: TurnNewsDialog (populated digest) @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the overflow contract — keeps the 320 dp positive pins '
        'meaningful)', (WidgetTester tester) async {
      await _pumpDialogAtSize(
        tester,
        TurnNewsDialog(
          game: baseGame,
          digest: const TurnNewsDigest(
            resolvedTurnNumber: 1,
            lines: <TurnNewsLine>[
              TurnNewsDiplomacyLine(
                factionIdA: 'gp1',
                factionIdB: 'gp2',
                kind: TurnNewsDiplomacyKind.war,
              ),
            ],
          ),
          newTurnNumber: 2,
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Turn 2'), findsOneWidget);
      expect(find.text('England and France are now at war.'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — GameMapOptionsDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    // Initial state mirrors the production seed: overlay and ownership tint
    // ON by default, names layer OFF (matches `MapViewState()` defaults from
    // `colonizethis_models` and the `mapViewStateNotifierProvider` seed used
    // by `GameMapArea`).
    const MapViewState baseState = MapViewState(
      showProvinceOverlay: true,
      showProvinceOwnershipTint: true,
      showProvinceNamesLayer: false,
    );

    testWidgets(
      'AC (positive) GameMapOptionsDialog @ 320×640: no RenderFlex '
      'overflow exception, title + 3 toggle labels + Close action render '
      '(all three Expanded labels + 12 dp gap + CtToggleSwitch rows must '
      'fit within the ~288 dp content width)',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          GameMapOptionsDialog(
            initialState: baseState,
            onChanged: (_) {},
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: GameMapOptionsDialog must '
              'not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The Expanded label + 12 dp gap + '
              'CtToggleSwitch row contract from '
              'SPEC/ui/empire-overview.md § Map display options must wrap '
              'within the ~288 dp CtDialogShell content column.',
        );
        expect(find.text('Map display options'), findsOneWidget);
        expect(find.text('Show province overlay'), findsOneWidget);
        expect(find.text('Show province ownership'), findsOneWidget);
        expect(find.text('Show province names'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      },
    );

    testWidgets('Negative control: GameMapOptionsDialog @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        GameMapOptionsDialog(
          initialState: baseState,
          onChanged: (_) {},
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Map display options'), findsOneWidget);
      expect(find.text('Show province overlay'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — TurnResolutionProcessingDialog '
      '@ 320 dp (Refs #2870 S8/S10)', () {
    const String phaseText = 'Resolving turn 3...';

    testWidgets(
      'AC (positive) TurnResolutionProcessingDialog @ 320×640: no '
      'RenderFlex overflow exception, title + phase text render '
      '(the CtLoadingIndicator + 10 dp gap + Expanded phase-text row must '
      'fit within the ~288 dp CtDialogShell content column)',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          const TurnResolutionProcessingDialog(phaseText: phaseText),
          size: _kMinViewport,
          settle: false,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: '
              'TurnResolutionProcessingDialog must not emit a RenderFlex '
              'overflow exception at kMinViewportWidth (320 dp). The '
              'CtLoadingIndicator + Expanded(phase text) row from '
              'SPEC/program/turn-resolution.md (Processing-turn modal) must '
              'wrap within the ~288 dp CtDialogShell content column.',
        );
        expect(find.text('Processing Turn'), findsOneWidget);
        expect(find.text(phaseText), findsOneWidget);
      },
    );

    testWidgets('Negative control: TurnResolutionProcessingDialog @ '
        '1024×768 also pumps without exception (regression sentinel for '
        'the overflow contract — keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
      await _pumpDialogAtSize(
        tester,
        const TurnResolutionProcessingDialog(phaseText: phaseText),
        size: _kWideRegressionViewport,
        settle: false,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Processing Turn'), findsOneWidget);
      expect(find.text(phaseText), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — CombatModeChoiceDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    const String provinceName = 'Lisbon';

    testWidgets(
      'AC (positive) CombatModeChoiceDialog (regular province) @ 320×640: '
      'no RenderFlex overflow exception, title + both action labels render '
      '(the end-aligned Auto-Resolve + 8 dp gap + Quick Battle row must fit '
      'within the ~288 dp CtDialogShell content column)',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: provinceName,
            isCapitalSiege: false,
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: CombatModeChoiceDialog '
              '(regular province) must not emit a RenderFlex overflow '
              'exception at kMinViewportWidth (320 dp). The title + muted '
              'body + end-aligned Auto-Resolve / Quick Battle '
              'CtNinePatchButton row from '
              'SPEC/ui/combat-mode-choice-dialog.md must wrap within the '
              '~288 dp CtDialogShell content column.',
        );
        expect(find.textContaining(provinceName), findsOneWidget);
        expect(find.textContaining('Auto-Resolve'), findsOneWidget);
        expect(find.textContaining('Quick Battle'), findsOneWidget);
      },
    );

    testWidgets('Negative control: CombatModeChoiceDialog (regular province) '
        '@ 1024×768 also pumps without exception (regression sentinel for '
        'the overflow contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        CombatModeChoiceDialog(
          bus: AppEventBus.create(),
          provinceName: provinceName,
          isCapitalSiege: false,
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining(provinceName), findsOneWidget);
      expect(find.textContaining('Auto-Resolve'), findsOneWidget);
      expect(find.textContaining('Quick Battle'), findsOneWidget);
    });

    testWidgets(
      'AC (positive) CombatModeChoiceDialog (capital siege) @ 320×640: '
      'no RenderFlex overflow exception, title + Quick Battle action render '
      '(Auto-Resolve is hidden; the single end-aligned Quick Battle button '
      'must fit within the ~288 dp CtDialogShell content column)',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Madrid',
            isCapitalSiege: true,
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: CombatModeChoiceDialog '
              '(capital siege) must not emit a RenderFlex overflow '
              'exception at kMinViewportWidth (320 dp). The forced '
              'Quick Battle-only action row from '
              'SPEC/ui/combat-mode-choice-dialog.md must wrap within the '
              '~288 dp CtDialogShell content column.',
        );
        expect(find.textContaining('Madrid'), findsOneWidget);
        expect(find.textContaining('Auto-Resolve'), findsNothing);
        expect(find.textContaining('Quick Battle'), findsWidgets);
      },
    );

    testWidgets('Negative control: CombatModeChoiceDialog (capital siege) @ '
        '1024×768 also pumps without exception (regression sentinel for the '
        'overflow contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        CombatModeChoiceDialog(
          bus: AppEventBus.create(),
          provinceName: 'Madrid',
          isCapitalSiege: true,
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Madrid'), findsOneWidget);
      expect(find.textContaining('Auto-Resolve'), findsNothing);
      expect(find.textContaining('Quick Battle'), findsWidgets);
    });
  });
}
