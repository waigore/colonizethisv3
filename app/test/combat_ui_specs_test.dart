// Pins SPEC/ui combat dialog and sub-view contracts:
// - SPEC/ui/quick-battle-deployment-view.md
// - SPEC/ui/quick-battle-action-selector.md
// - SPEC/ui/combat-mode-choice-dialog.md
// - SPEC/ui/quick-battle-result-dialog.md

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_action_selector.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_deployment_view.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

Widget _frame(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

Widget _darkFrame(Widget child) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(body: child),
  );
}

void main() {
  suppressLogsForTests();

  group('QuickBattleDeploymentView (SPEC/ui/quick-battle-deployment-view.md)', () {
    testWidgets('renders attacker and defender headers with custom names',
        (WidgetTester tester) async {
      await tester.pumpWidget(_frame(
        const QuickBattleDeploymentView(
          attackerDeployment: QuickBattleDeployment(
            groups: [
              QuickBattleGroup(
                lane: QuickBattleLane.center,
                line: QuickBattleLine.front,
                unitIds: ['a1', 'a2', 'a3'],
                cohesion: 3,
              ),
            ],
          ),
          defenderDeployment: QuickBattleDeployment(
            groups: [
              QuickBattleGroup(
                lane: QuickBattleLane.center,
                line: QuickBattleLine.front,
                unitIds: ['d1', 'd2'],
                cohesion: 3,
              ),
            ],
          ),
          attackerName: 'Castile',
          defenderName: 'England',
        ),
      ));

      expect(find.text('Castile'), findsOneWidget);
      expect(find.text('England'), findsOneWidget);
      expect(find.text('Center Front: 3 units (Cohesion 3)'), findsOneWidget);
      expect(find.text('Center Front: 2 units (Cohesion 3)'), findsOneWidget);
    });

    testWidgets('omits cohesion suffix when cohesion is 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(_frame(
        const QuickBattleDeploymentView(
          attackerDeployment: QuickBattleDeployment(
            groups: [
              QuickBattleGroup(
                lane: QuickBattleLane.center,
                line: QuickBattleLine.front,
                unitIds: ['a1'],
                cohesion: 0,
              ),
            ],
          ),
          defenderDeployment: QuickBattleDeployment(
            groups: [
              QuickBattleGroup(
                lane: QuickBattleLane.center,
                line: QuickBattleLine.front,
                unitIds: ['d1'],
                cohesion: 1,
              ),
            ],
          ),
        ),
      ));

      expect(find.text('Center Front: 1 units'), findsOneWidget);
      expect(find.text('Center Front: 1 units (Cohesion 1)'), findsOneWidget);
    });

    testWidgets('uses default Attacker / Defender headers when names are omitted',
        (WidgetTester tester) async {
      await tester.pumpWidget(_frame(
        const QuickBattleDeploymentView(
          attackerDeployment: QuickBattleDeployment(),
          defenderDeployment: QuickBattleDeployment(),
        ),
      ));

      expect(find.text('Attacker'), findsOneWidget);
      expect(find.text('Defender'), findsOneWidget);
    });
  });

  group('QuickBattleActionSelector (SPEC/ui/quick-battle-action-selector.md)', () {
    testWidgets('with cpRemaining=3 every action button is enabled',
        (WidgetTester tester) async {
      QuickBattleAction? picked;
      await tester.pumpWidget(_frame(
        QuickBattleActionSelector(
          cpRemaining: 3,
          onActionSelected: (a) => picked = a,
        ),
      ));

      // No Material buttons in the selector — pixel-art only.
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);

      await tester.tap(find.textContaining('Volley Fire'));
      await tester.pump();
      expect(picked, QuickBattleAction.volleyFire);
    });

    testWidgets('with cpRemaining=1 the 2-CP buttons are disabled',
        (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(_frame(
        QuickBattleActionSelector(
          cpRemaining: 1,
          onActionSelected: (_) => taps++,
        ),
      ));

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

    testWidgets('with cpRemaining=0 every action button is disabled',
        (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(_frame(
        QuickBattleActionSelector(
          cpRemaining: 0,
          onActionSelected: (_) => taps++,
        ),
      ));

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
  });

  group('CombatModeChoiceDialog (SPEC/ui/combat-mode-choice-dialog.md)', () {
    testWidgets(
        'regular province emits autoResolve on Auto-Resolve and pops the route',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final received = <CombatMode>[];
      final sub = bus.on<CombatModeChosenEvent>().listen((e) {
        received.add(e.mode);
      });
      addTearDown(() async {
        await sub.cancel();
      });

      await tester.pumpWidget(_frame(
        Builder(builder: (ctx) {
          return TextButton(
            child: const Text('open'),
            onPressed: () {
              showDialog<void>(
                context: ctx,
                builder: (_) => CombatModeChoiceDialog(
                  bus: bus,
                  provinceName: 'Lisbon',
                  isCapitalSiege: false,
                ),
              );
            },
          );
        }),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lisbon'), findsOneWidget);
      expect(find.textContaining('Auto-Resolve'), findsOneWidget);
      expect(find.textContaining('Quick Battle'), findsOneWidget);

      await tester.tap(find.textContaining('Auto-Resolve'));
      await tester.pumpAndSettle();

      expect(received, [CombatMode.autoResolve]);
      // Dialog popped — the underlying open button is visible again.
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('regular province emits quickBattle on Quick Battle',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final received = <CombatMode>[];
      final sub = bus.on<CombatModeChosenEvent>().listen((e) {
        received.add(e.mode);
      });
      addTearDown(() async {
        await sub.cancel();
      });

      await tester.pumpWidget(_frame(
        Builder(builder: (ctx) {
          return TextButton(
            child: const Text('open'),
            onPressed: () {
              showDialog<void>(
                context: ctx,
                builder: (_) => CombatModeChoiceDialog(
                  bus: bus,
                  provinceName: 'Lisbon',
                  isCapitalSiege: false,
                ),
              );
            },
          );
        }),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Quick Battle'));
      await tester.pumpAndSettle();

      expect(received, [CombatMode.quickBattle]);
    });

    testWidgets('capital siege variant only renders Quick Battle button',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final received = <CombatMode>[];
      final sub = bus.on<CombatModeChosenEvent>().listen((e) {
        received.add(e.mode);
      });
      addTearDown(() async {
        await sub.cancel();
      });

      await tester.pumpWidget(_frame(
        Builder(builder: (ctx) {
          return TextButton(
            child: const Text('open'),
            onPressed: () {
              showDialog<void>(
                context: ctx,
                builder: (_) => CombatModeChoiceDialog(
                  bus: bus,
                  provinceName: 'Madrid',
                  isCapitalSiege: true,
                ),
              );
            },
          );
        }),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

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
        'dark editorial-monocle chrome: title resolves to --accent + 0.05 letter-spacing',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      await tester.pumpWidget(_darkFrame(
        CombatModeChoiceDialog(
          bus: bus,
          provinceName: 'Lisbon',
          isCapitalSiege: false,
        ),
      ));

      final Text title = tester.widget<Text>(find.textContaining('Lisbon'));
      expect(title.style?.color, EditorialMonoclePalette.accent);
      expect(title.style?.letterSpacing, 0.05);
    });

    testWidgets(
        'dark editorial-monocle chrome: regular body text resolves to --muted',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      await tester.pumpWidget(_darkFrame(
        CombatModeChoiceDialog(
          bus: bus,
          provinceName: 'Lisbon',
          isCapitalSiege: false,
        ),
      ));

      final Text body = tester.widget<Text>(find.text('Choose combat mode:'));
      expect(body.style?.color, EditorialMonoclePalette.muted);
    });

    testWidgets(
        'dark editorial-monocle chrome: capital-siege body text resolves to --muted',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      await tester.pumpWidget(_darkFrame(
        CombatModeChoiceDialog(
          bus: bus,
          provinceName: 'Madrid',
          isCapitalSiege: true,
        ),
      ));

      final Finder bodyFinder = find.text(
        'Capital siege — Quick Battle only (no auto-resolve).',
      );
      expect(bodyFinder, findsOneWidget);
      final Text body = tester.widget<Text>(bodyFinder);
      expect(body.style?.color, EditorialMonoclePalette.muted);
    });

    testWidgets(
        'dark editorial-monocle chrome: Quick Battle label resolves to --accent, Auto-Resolve label resolves to --muted',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      await tester.pumpWidget(_darkFrame(
        CombatModeChoiceDialog(
          bus: bus,
          provinceName: 'Lisbon',
          isCapitalSiege: false,
        ),
      ));

      final Text autoLabel = tester.widget<Text>(find.text('Auto-Resolve'));
      expect(autoLabel.style?.color, EditorialMonoclePalette.muted);

      final Text qbLabel = tester.widget<Text>(find.text('Quick Battle'));
      expect(qbLabel.style?.color, EditorialMonoclePalette.accent);
    });

    testWidgets(
        'dark editorial-monocle chrome: regular variant has exactly one CtDialogShell and zero Material action buttons',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      await tester.pumpWidget(_darkFrame(
        CombatModeChoiceDialog(
          bus: bus,
          provinceName: 'Lisbon',
          isCapitalSiege: false,
        ),
      ));

      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('QuickBattleResultDialog (SPEC/ui/quick-battle-result-dialog.md)', () {
    testWidgets('attacker wins + provinceFlips renders captured banner',
        (WidgetTester tester) async {
      await tester.pumpWidget(_frame(
        const QuickBattleResultDialog(
          result: QuickBattleResult(
            winner: QuickBattleWinner.attacker,
            attackerCasualties: ['a3'],
            defenderCasualties: ['d1', 'd2'],
            provinceFlips: true,
          ),
          attackerName: 'Castile',
          defenderName: 'England',
        ),
      ));

      expect(find.textContaining('Castile'), findsWidgets);
      expect(find.textContaining('England'), findsWidgets);
      expect(find.textContaining('captured'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('defender holds suppresses captured banner',
        (WidgetTester tester) async {
      await tester.pumpWidget(_frame(
        const QuickBattleResultDialog(
          result: QuickBattleResult(
            winner: QuickBattleWinner.defender,
            attackerCasualties: ['a1', 'a2'],
            defenderCasualties: ['d1'],
            provinceFlips: false,
          ),
          attackerName: 'Castile',
          defenderName: 'England',
        ),
      ));

      expect(find.textContaining('captured'), findsNothing);
    });

    testWidgets('mutual exhaustion suppresses captured banner',
        (WidgetTester tester) async {
      await tester.pumpWidget(_frame(
        const QuickBattleResultDialog(
          result: QuickBattleResult(
            winner: QuickBattleWinner.mutualExhaustion,
            attackerCasualties: ['a1'],
            defenderCasualties: ['d1'],
            provinceFlips: false,
          ),
        ),
      ));

      expect(find.textContaining('captured'), findsNothing);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('OK button pops the dialog route',
        (WidgetTester tester) async {
      await tester.pumpWidget(_frame(
        Builder(builder: (ctx) {
          return TextButton(
            child: const Text('open'),
            onPressed: () {
              showDialog<void>(
                context: ctx,
                builder: (_) => const QuickBattleResultDialog(
                  result: QuickBattleResult(
                    winner: QuickBattleWinner.attacker,
                    attackerCasualties: [],
                    defenderCasualties: [],
                    provinceFlips: true,
                  ),
                ),
              );
            },
          );
        }),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsNothing);
      // Underlying open button is visible again — dialog popped.
      expect(find.text('open'), findsOneWidget);
    });
  });
}
