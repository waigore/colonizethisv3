// Extended 320 dp dialog pins for part1 (Refs #4352).

import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/flame/overlays/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

void registerDialogs320Part1ExtendedTests() {
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
        await pumpDialogs320At(
          tester,
          TurnNewsDialog(
            game: baseGame,
            digest: const TurnNewsDigest(
              resolvedTurnNumber: 1,
              lines: <TurnNewsLine>[],
            ),
            newTurnNumber: 2,
          ),
          size: kDialogs320MinViewport,
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
        await pumpDialogs320At(
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
          size: kDialogs320MinViewport,
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
        await pumpDialogs320At(
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
          size: kDialogs320WideRegressionViewport,
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

      testWidgets('AC (positive) GameMapOptionsDialog @ 320×640: no RenderFlex '
          'overflow exception, title + 4 toggle labels + Close action render '
          '(all four Expanded labels + 12 dp gap + CtToggleSwitch rows must '
          'fit within the ~288 dp content width)', (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          GameMapOptionsDialog(initialState: baseState, onChanged: (_) {}),
          size: kDialogs320MinViewport,
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
      });

      testWidgets('Negative control: GameMapOptionsDialog @ 1024×768 also '
          'pumps without exception (regression sentinel for the overflow '
          'contract — keeps the 320 dp positive pin meaningful)', (
        WidgetTester tester,
      ) async {
        await pumpDialogs320At(
          tester,
          GameMapOptionsDialog(initialState: baseState, onChanged: (_) {}),
          size: kDialogs320WideRegressionViewport,
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

      testWidgets('AC (positive) TurnResolutionProcessingDialog @ 320×640: no '
          'RenderFlex overflow exception, title + phase text render '
          '(the CtLoadingIndicator + 10 dp gap + Expanded phase-text row must '
          'fit within the ~288 dp CtDialogShell content column)', (
        WidgetTester tester,
      ) async {
        await pumpDialogs320At(
          tester,
          const TurnResolutionProcessingDialog(phaseText: phaseText),
          size: kDialogs320MinViewport,
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
      });

      testWidgets('Negative control: TurnResolutionProcessingDialog @ '
          '1024×768 also pumps without exception (regression sentinel for '
          'the overflow contract — keeps the 320 dp positive pin meaningful)', (
        WidgetTester tester,
      ) async {
        await pumpDialogs320At(
          tester,
          const TurnResolutionProcessingDialog(phaseText: phaseText),
          size: kDialogs320WideRegressionViewport,
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
          await pumpDialogs320At(
            tester,
            CombatModeChoiceDialog(
              bus: AppEventBus.create(),
              provinceName: provinceName,
              isCapitalSiege: false,
            ),
            size: kDialogs320MinViewport,
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
        await pumpDialogs320At(
          tester,
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: provinceName,
            isCapitalSiege: false,
          ),
          size: kDialogs320WideRegressionViewport,
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
          await pumpDialogs320At(
            tester,
            CombatModeChoiceDialog(
              bus: AppEventBus.create(),
              provinceName: 'Madrid',
              isCapitalSiege: true,
            ),
            size: kDialogs320MinViewport,
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
        await pumpDialogs320At(
          tester,
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Madrid',
            isCapitalSiege: true,
          ),
          size: kDialogs320WideRegressionViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Madrid'), findsOneWidget);
        expect(find.textContaining('Auto-Resolve'), findsNothing);
        expect(find.textContaining('Quick Battle'), findsWidgets);
      });
    });
}
