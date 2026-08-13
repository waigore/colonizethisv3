// Pins SPEC/ui combat dialog and sub-view contracts (part 1):
// - SPEC/ui/quick-battle-deployment-view.md
// - SPEC/ui/quick-battle-action-selector.md
// - SPEC/ui/combat-mode-choice-dialog.md
// Split under repo.app_test_file_size (Refs #4013).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'combat_ui_specs_test_support.dart';

void main() {

  suppressLogsForTests();

  group(
    'QuickBattleDeploymentView (SPEC/ui/quick-battle-deployment-view.md)',
    () {
      testWidgets('renders attacker and defender headers with custom names', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          combatUiSpecsFrame(
            combatUiSpecsDeploymentView(
              attackerGroups: [combatUiSpecsCenterFront(unitIds: const ['a1', 'a2', 'a3'])],
              defenderGroups: [combatUiSpecsCenterFront(unitIds: const ['d1', 'd2'])],
              attackerName: 'Castile',
              defenderName: 'England',
            ),
          ),
        );

        expect(find.text('Castile'), findsOneWidget);
        expect(find.text('England'), findsOneWidget);
        expect(find.text('Center Front: 3 units (Cohesion 3)'), findsOneWidget);
        expect(find.text('Center Front: 2 units (Cohesion 3)'), findsOneWidget);
      });

      testWidgets('omits cohesion suffix when cohesion is 0', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          combatUiSpecsFrame(
            combatUiSpecsDeploymentView(
              attackerGroups: [
                combatUiSpecsCenterFront(unitIds: const ['a1'], cohesion: 0),
              ],
              defenderGroups: [
                combatUiSpecsCenterFront(unitIds: const ['d1'], cohesion: 1),
              ],
            ),
          ),
        );

        expect(find.text('Center Front: 1 units'), findsOneWidget);
        expect(find.text('Center Front: 1 units (Cohesion 1)'), findsOneWidget);
      });

      testWidgets(
        'uses default Attacker / Defender headers when names are omitted',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            combatUiSpecsFrame(combatUiSpecsDeploymentView()),
          );

          expect(find.text('Attacker'), findsOneWidget);
          expect(find.text('Defender'), findsOneWidget);
        },
      );

      // Refs #2869 R14 + SPEC/ui/quick-battle-deployment-view.md § Layout.
      testWidgets(
        'group-row text resolves to --muted under dark and fallback themes',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            combatUiSpecsDarkFrame(
              combatUiSpecsDeploymentView(
                attackerGroups: [
                  combatUiSpecsCenterFront(unitIds: const ['a1', 'a2', 'a3']),
                ],
                defenderGroups: [
                  combatUiSpecsCenterFront(unitIds: const ['d1'], cohesion: 0),
                ],
              ),
            ),
          );
          expect(
            tester
                .widget<Text>(find.text('Center Front: 3 units (Cohesion 3)'))
                .style
                ?.color,
            EditorialMonoclePalette.muted,
          );
          expect(
            tester.widget<Text>(find.text('Center Front: 1 units')).style?.color,
            EditorialMonoclePalette.muted,
          );

          await tester.pumpWidget(
            combatUiSpecsFrame(
              combatUiSpecsDeploymentView(
                attackerGroups: [
                  combatUiSpecsCenterFront(unitIds: const ['a1'], cohesion: 2),
                ],
              ),
            ),
          );
          expect(
            tester
                .widget<Text>(find.text('Center Front: 1 units (Cohesion 2)'))
                .style
                ?.color,
            EditorialMonoclePalette.muted,
          );
        },
      );
    },
  );

  group(
    'QuickBattleActionSelector (SPEC/ui/quick-battle-action-selector.md)',
    () {
      testWidgets('with cpRemaining=3 every action button is enabled', (
        WidgetTester tester,
      ) async {
        QuickBattleAction? picked;
        await pumpCombatUiSpecsSelector(
          tester,
          cpRemaining: 3,
          onActionSelected: (a) => picked = a,
        );

        // No Material buttons in the selector — pixel-art only.
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(TextButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);

        await tester.tap(find.textContaining('Volley Fire'));
        await tester.pump();
        expect(picked, QuickBattleAction.volleyFire);
      });

      testWidgets('with cpRemaining=1 the 2-CP buttons are disabled', (
        WidgetTester tester,
      ) async {
        var taps = 0;
        await pumpCombatUiSpecsSelector(
          tester,
          cpRemaining: 1,
          onActionSelected: (_) => taps++,
        );

        // 1-CP action remains tappable.
        await tester.tap(find.textContaining('Volley Fire'));
        await tester.pump();
        expect(taps, 1);

        // 2-CP actions must not invoke the callback (button disabled, hit-test no-op).
        await tester.tap(find.textContaining('Assault'), warnIfMissed: false);
        await tester.pump();
        expect(taps, 1);

        await tester.tap(find.textContaining('Fall Back'), warnIfMissed: false);
        await tester.pump();
        expect(taps, 1);
      });

      testWidgets('with cpRemaining=0 every action button is disabled', (
        WidgetTester tester,
      ) async {
        var taps = 0;
        await pumpCombatUiSpecsSelector(
          tester,
          cpRemaining: 0,
          onActionSelected: (_) => taps++,
        );

        for (final label in const [
          'Volley Fire',
          'Defend',
          'Maneuver',
          'Fall Back',
          'Assault',
        ]) {
          await tester.tap(find.textContaining(label), warnIfMissed: false);
        }
        await tester.pump();
        expect(taps, 0);
      });

      // Refs #2869 R17 + SPEC/ui/quick-battle-action-selector.md § Layout.
      testWidgets(
        'CP indicator resolves to --muted under dark and fallback themes',
        (WidgetTester tester) async {
          await pumpCombatUiSpecsSelector(
            tester,
            cpRemaining: 3,
            onActionSelected: (_) {},
            dark: true,
          );
          expect(
            tester
                .widget<Text>(find.textContaining('Command Points: 3'))
                .style
                ?.color,
            EditorialMonoclePalette.muted,
          );

          await pumpCombatUiSpecsSelector(tester, cpRemaining: 0, onActionSelected: (_) {});
          expect(
            tester
                .widget<Text>(find.textContaining('Command Points: 0'))
                .style
                ?.color,
            EditorialMonoclePalette.muted,
          );
        },
      );
    },
  );

  group('CombatModeChoiceDialog (SPEC/ui/combat-mode-choice-dialog.md)', () {
    testWidgets(
      'regular province emits autoResolve / quickBattle and pops on Auto-Resolve',
      (WidgetTester tester) async {
        for (final case_ in <(String, CombatMode)>[
          ('Auto-Resolve', CombatMode.autoResolve),
          ('Quick Battle', CombatMode.quickBattle),
        ]) {
          final (bus, received) = listenCombatUiSpecsModes();
          await openCombatUiSpecsModeChoice(
            tester,
            bus: bus,
            provinceName: 'Lisbon',
            isCapitalSiege: false,
          );
          expect(find.textContaining('Lisbon'), findsOneWidget);
          expect(find.textContaining('Auto-Resolve'), findsOneWidget);
          expect(find.textContaining('Quick Battle'), findsOneWidget);

          await tester.tap(find.textContaining(case_.$1));
          await tester.pumpAndSettle();
          expect(received, [case_.$2]);
          if (case_.$2 == CombatMode.autoResolve) {
            // Dialog popped — the underlying open button is visible again.
            expect(find.text('open'), findsOneWidget);
          }
        }
      },
    );

    testWidgets('shows land underfed soft warning when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        combatUiSpecsDarkFrame(
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Lisbon',
            isCapitalSiege: false,
            landForceFeedingWarning:
                'Your armies are short on rations — they will fight somewhat weaker this turn.',
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'Your armies are short on rations — they will fight somewhat weaker this turn.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Auto-Resolve'), findsOneWidget);
      expect(find.textContaining('Quick Battle'), findsOneWidget);
    });

    testWidgets('capital siege variant only renders Quick Battle button', (
      WidgetTester tester,
    ) async {
      final (bus, received) = listenCombatUiSpecsModes();
      await openCombatUiSpecsModeChoice(
        tester,
        bus: bus,
        provinceName: 'Madrid',
        isCapitalSiege: true,
      );

      expect(find.textContaining('Auto-Resolve'), findsNothing);
      // Exactly one pixel-art button is rendered (the Quick Battle button);
      // the body text may also include the phrase "Quick Battle" so we count
      // CtNinePatchButton instances rather than text occurrences.
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await tester.tap(find.byType(CtNinePatchButton));
      await tester.pumpAndSettle();

      expect(received, [CombatMode.quickBattle]);
    });

    testWidgets(
      'dark editorial-monocle chrome: Lisbon regular + Madrid capital siege',
      (WidgetTester tester) async {
        await pumpDarkCombatUiSpecsModeChoice(
          tester,
          provinceName: 'Lisbon',
          isCapitalSiege: false,
        );

        final Text title = tester.widget<Text>(find.textContaining('Lisbon'));
        expect(title.style?.color, EditorialMonoclePalette.accent);
        expect(title.style?.letterSpacing, 0.05);

        final Text body = tester.widget<Text>(find.text('Choose combat mode:'));
        expect(body.style?.color, EditorialMonoclePalette.muted);

        expect(
          tester.widget<Text>(find.text('Auto-Resolve')).style?.color,
          EditorialMonoclePalette.muted,
        );
        expect(
          tester.widget<Text>(find.text('Quick Battle')).style?.color,
          EditorialMonoclePalette.accent,
        );
        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.byType(FilledButton), findsNothing);

        await pumpDarkCombatUiSpecsModeChoice(
          tester,
          provinceName: 'Madrid',
          isCapitalSiege: true,
        );
        final Finder siegeBody = find.text(
          'Capital siege — Quick Battle only (no auto-resolve).',
        );
        expect(siegeBody, findsOneWidget);
        expect(
          tester.widget<Text>(siegeBody).style?.color,
          EditorialMonoclePalette.muted,
        );
      },
    );
  });
}
