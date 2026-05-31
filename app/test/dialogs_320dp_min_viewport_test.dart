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
//  * [NextTurnConfirmationDialog]        — top-bar "Next turn" confirm (DLG60001)
//    (SPEC/ui/next-turn-confirmation.md).
//  * [QuickBattleResultDialog]           — post–Quick Battle outcome modal
//    (SPEC/ui/quick-battle-result-dialog.md).
//  * [SplitArmyDialog]                   — split regiments from one army
//    into a new army at the same province
//    (SPEC/ui/military-units-army-management.md).
//  * [SplitFleetDialog]                  — split ships from one fleet
//    into a new fleet at the same sea-zone or port
//    (SPEC/game/ships-and-naval.md § Fleet management).
//  * [TransferToHomeFleetDialog]         — transfer ships from a source
//    fleet into the player's home fleet in port
//    (SPEC/ui/transfer-to-home-fleet-dialog.md).
//
// All eleven dialogs render their chrome via [CtDialogShell]. The first
// eight pass `maxWidth: 400` or `maxWidth: 480`; the three new
// CtTransferList-hosted dialogs (split army / split fleet / transfer to
// home fleet) pass the wider `maxWidth: 520` / `maxWidth: 560` so the
// side-by-side columns can render at default widths. At
// `kMinViewportWidth` (320 dp) every shell collapses to the same ~288 dp
// content width — the outer `Dialog.insetPadding` (16 dp each side)
// dominates whenever the viewport is narrower than the configured
// `maxWidth`, so the wider CtTransferList dialogs share the same narrow
// budget as the simpler shells in this file. The pins assert:
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
// SPEC: `SPEC/ui/next-turn-confirmation.md`.
// SPEC: `SPEC/ui/quick-battle-result-dialog.md`.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/flame/exit_confirm_dialog.dart';
import 'package:colonizethis_app/features/game/flame/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/flame/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/game_map_options_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/game_parameters_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/split_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/split_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/turn_news_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
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
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

  group('SPEC/ui/mobile-adaptation.md § 7 — NextTurnConfirmationDialog '
      '@ 320 dp (Refs #2870 S8/S10)', () {
    const int currentTurn = 7;

    testWidgets(
      'AC (positive) NextTurnConfirmationDialog @ 320×640: no '
      'RenderFlex overflow exception, title + body + No + Yes render '
      '(the end-aligned No + 8 dp gap + Yes row must fit within the '
      '~288 dp CtDialogShell content column)',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          const NextTurnConfirmationDialog(currentTurn: currentTurn),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: NextTurnConfirmationDialog '
              'must not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The title + body + end-aligned '
              'No / Yes CtNinePatchButton row from '
              'SPEC/ui/next-turn-confirmation.md must wrap within the '
              '~288 dp CtDialogShell content column.',
        );
        expect(find.text('End turn?'), findsOneWidget);
        expect(find.textContaining('Turn 7 will end'), findsOneWidget);
        expect(find.text('No'), findsOneWidget);
        expect(find.text('Yes'), findsOneWidget);
      },
    );

    testWidgets('Negative control: NextTurnConfirmationDialog @ 1024×768 '
        'also pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        const NextTurnConfirmationDialog(currentTurn: currentTurn),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('End turn?'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — QuickBattleResultDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    const QuickBattleResult attackerWinsFlips = QuickBattleResult(
      winner: QuickBattleWinner.attacker,
      attackerCasualties: ['a3'],
      defenderCasualties: ['d1', 'd2'],
      provinceFlips: true,
    );

    testWidgets(
      'AC (positive) QuickBattleResultDialog (attacker wins, provinceFlips) '
      '@ 320×640: no RenderFlex overflow exception, winner + captured banner '
      '+ casualty rows + OK render (the title + optional captured line + two '
      'casualty bodySmall rows + trailing OK must fit within the ~288 dp '
      'CtDialogShell content column)',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          const QuickBattleResultDialog(
            result: attackerWinsFlips,
            attackerName: 'Castile',
            defenderName: 'England',
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: QuickBattleResultDialog '
              '(attacker wins + provinceFlips) must not emit a RenderFlex '
              'overflow exception at kMinViewportWidth (320 dp). The winner '
              'title, captured banner, casualty rows, and trailing OK action '
              'from SPEC/ui/quick-battle-result-dialog.md must wrap within '
              'the ~288 dp CtDialogShell content column.',
        );
        expect(find.textContaining('Castile'), findsWidgets);
        expect(find.textContaining('England'), findsWidgets);
        expect(find.textContaining('captured'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
      },
    );

    testWidgets('Negative control: QuickBattleResultDialog @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        const QuickBattleResultDialog(
          result: attackerWinsFlips,
          attackerName: 'Castile',
          defenderName: 'England',
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Castile'), findsWidgets);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — SplitArmyDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    // Minimal Game fixture: one human GP, one province in oldWorld owned by
    // the human, one in-province levy regiment. Mirrors the fixture shape
    // used by `split_army_dialog_test.dart` so the narrow pin exercises the
    // same `CtTransferList` layout path that ships in production.
    Game gameWithOneRegimentArmy() {
      const province = Province(
        id: 'cap',
        regionId: 'oldWorld',
        displayName: 'Lisbon',
      );
      final unit = Unit(
        id: 'levy_1',
        type: 'peasant_levy',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|cap',
      );
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [province],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
    }

    final Army oneLevyArmy = Army(
      id: 'army_1',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      stationedProvinceId: 'oldWorld|cap',
      regimentUnitIds: const ['levy_1'],
    );

    testWidgets(
      'AC (positive) SplitArmyDialog (non-home) @ 320×640: no RenderFlex '
      'overflow exception, "Split Army" title + "Confirm Split" action + '
      'transfer-list left/right column titles render',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          SplitArmyDialog(
            army: oneLevyArmy,
            game: gameWithOneRegimentArmy(),
            humanPlayerId: 'gp1',
            bus: AppEventBus.create(),
            isHomeArmy: false,
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: SplitArmyDialog must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). The "Split Army" title + side-by-side '
              'CtTransferList columns ("Army <id>" + "New Army") with '
              'shared 220 dp list height, the +/- move controls, and the '
              'trailing Cancel / Confirm Split row must all fit within '
              'the ~288 dp CtDialogShell content column at 320 dp — '
              'CtDialogShell `maxWidth: 520` does not take effect at this '
              'viewport because `Dialog.insetPadding` (16 dp each side) '
              'dominates, leaving the same ~288 dp budget as the simpler '
              'shells pinned above this group.',
        );
        expect(find.text('Split Army'), findsOneWidget);
        expect(find.text('Confirm Split'), findsOneWidget);
        // CtTransferList column titles surface so the dialog body is
        // actually exercised at the narrow size (vs an empty no-op).
        expect(find.text('Army army_1'), findsOneWidget);
        expect(find.text('New Army'), findsOneWidget);
      },
    );

    testWidgets('Negative control: SplitArmyDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        SplitArmyDialog(
          army: oneLevyArmy,
          game: gameWithOneRegimentArmy(),
          humanPlayerId: 'gp1',
          bus: AppEventBus.create(),
          isHomeArmy: false,
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Split Army'), findsOneWidget);
      expect(find.text('Confirm Split'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — SplitFleetDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    // Minimal Game fixture: one human GP, one sea-zone display name so the
    // dialog's `_fleetLocationLabel()` resolves to a non-"Unknown" string,
    // and no provinces (the at-sea fleet does not need one). Mirrors the
    // at-sea fixture used by `split_fleet_dialog_test.dart`.
    Game minimalSeaZoneGame() {
      return Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(),
          newWorld: RegionData(),
          seaZoneDisplayNameById: {'oldWorld|s1': 'Adriatic Display'},
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
    }

    final Fleet oneCarrackAtSea = Fleet(
      id: 'f_split',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 's1',
      shipTypeIds: const ['carrack'],
    );

    testWidgets(
      'AC (positive) SplitFleetDialog (non-home) @ 320×640: no RenderFlex '
      'overflow exception, "Split Fleet" title + "Confirm Split" action + '
      'New Fleet right-column title render',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          SplitFleetDialog(
            originalFleet: oneCarrackAtSea,
            game: minimalSeaZoneGame(),
            humanPlayerId: 'gp1',
            bus: AppEventBus.create(),
            isHomeFleet: false,
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: SplitFleetDialog must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). The "Split Fleet" title + side-by-side '
              'CtTransferList columns ("Fleet <id>" + "New Fleet") with '
              'shared 220 dp list height, the +/- move controls, and the '
              'trailing Cancel / Confirm Split row must all fit within '
              'the ~288 dp CtDialogShell content column at 320 dp — '
              'CtDialogShell `maxWidth: 520` is dominated by '
              '`Dialog.insetPadding` at this viewport.',
        );
        expect(find.text('Split Fleet'), findsOneWidget);
        expect(find.text('Confirm Split'), findsOneWidget);
        // CtTransferList "New Fleet" right-column title surfaces so the
        // dialog body is actually exercised at the narrow size.
        expect(find.text('New Fleet'), findsOneWidget);
      },
    );

    testWidgets('Negative control: SplitFleetDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        SplitFleetDialog(
          originalFleet: oneCarrackAtSea,
          game: minimalSeaZoneGame(),
          humanPlayerId: 'gp1',
          bus: AppEventBus.create(),
          isHomeFleet: false,
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Split Fleet'), findsOneWidget);
      expect(find.text('Confirm Split'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — TransferToHomeFleetDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    // Minimal Game fixture: one human GP, one capital province (Lisbon) for
    // the in-port home fleet, and one sea-zone display name so the source
    // fleet's at-sea location label resolves to a non-"Unknown" string.
    Game gameWithCapitalAndSeaZone() {
      const capital = Province(
        id: 'cap',
        regionId: 'oldWorld',
        displayName: 'Lisbon',
      );
      return Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [capital]),
          newWorld: RegionData(),
          seaZoneDisplayNameById: {'oldWorld|s1': 'Adriatic'},
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
    }

    final Fleet sourceFleetAtSea = Fleet(
      id: 'f_src',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 's1',
      shipTypeIds: const ['carrack'],
    );

    final Fleet homeFleetInPort = Fleet(
      id: 'home_fleet',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      inPortAtProvinceId: 'oldWorld|cap',
      shipTypeIds: const ['carrack'],
    );

    testWidgets(
      'AC (positive) TransferToHomeFleetDialog @ 320×640: no RenderFlex '
      'overflow exception, dialog title + "Home Fleet" right column + '
      '"Transfer" action render',
      (WidgetTester tester) async {
        await _pumpDialogAtSize(
          tester,
          TransferToHomeFleetDialog(
            sourceFleet: sourceFleetAtSea,
            homeFleet: homeFleetInPort,
            game: gameWithCapitalAndSeaZone(),
            humanPlayerId: 'gp1',
            bus: AppEventBus.create(),
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: TransferToHomeFleetDialog '
              'must not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The title row + side-by-side '
              'CtTransferList columns ("Fleet <id>" + "Home Fleet") with '
              'shared 240 dp list height, the +/- move controls, and the '
              'trailing Cancel / Transfer action row must all fit within '
              'the ~288 dp CtDialogShell content column at 320 dp — '
              'CtDialogShell `maxWidth: 560` is dominated by '
              '`Dialog.insetPadding` at this viewport.',
        );
        expect(
          find.text('Transfer Ships to Home Fleet'),
          findsOneWidget,
        );
        expect(find.text('Transfer'), findsOneWidget);
        // Home Fleet right-column title surfaces so the dialog body is
        // actually exercised at the narrow size.
        expect(find.text('Home Fleet'), findsOneWidget);
      },
    );

    testWidgets('Negative control: TransferToHomeFleetDialog @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpDialogAtSize(
        tester,
        TransferToHomeFleetDialog(
          sourceFleet: sourceFleetAtSea,
          homeFleet: homeFleetInPort,
          game: gameWithCapitalAndSeaZone(),
          humanPlayerId: 'gp1',
          bus: AppEventBus.create(),
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('Transfer Ships to Home Fleet'),
        findsOneWidget,
      );
      expect(find.text('Transfer'), findsOneWidget);
    });
  });
}
