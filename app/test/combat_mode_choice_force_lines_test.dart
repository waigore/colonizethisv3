// Widget pins for CMPT10001 force/fort/Details/mode-meaning. Refs #4438.
// SPEC/ui/combat-mode-choice-dialog.md.

import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_intel.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'combat_ui_specs_test_support.dart';

const _attackerFull = CombatModeChoiceIntel(
  role: CombatModeChoiceRole.attacker,
  ownRegimentCount: 3,
  ownTypesByRegimentId: {'musketeers': 2, 'pikemen': 1},
  enemyRegimentCount: 2,
  enemyTypesByRegimentId: {'musketeers': 2},
  fortLevel: 1,
);

Future<void> _pump(
  WidgetTester tester, {
  bool isCapitalSiege = false,
  CombatModeChoiceIntel? intel,
  String? warning,
  bool detailsInitiallyOpen = false,
}) {
  return tester.pumpWidget(
    combatUiSpecsDarkFrame(
      CombatModeChoiceDialog(
        bus: AppEventBus.create(),
        provinceName: 'Lisbon',
        isCapitalSiege: isCapitalSiege,
        intel: intel,
        landForceFeedingWarning: warning,
        detailsInitiallyOpen: detailsInitiallyOpen,
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'attacker full intel shows own, defenders, wood siege, meanings',
    (WidgetTester tester) async {
      await _pump(tester, intel: _attackerFull);
      expect(find.text('Your army: 3 regiments'), findsOneWidget);
      expect(find.text('Defenders: 2 regiments'), findsOneWidget);
      expect(find.text('Wood fort siege'), findsOneWidget);
      expect(find.text('Decides the battle at once.'), findsOneWidget);
      expect(find.text('You give orders in the fight.'), findsOneWidget);
      expect(find.text('Unopposed capture'), findsNothing);
      expect(find.textContaining('Musketeers'), findsNothing);
    },
  );

  testWidgets('attacker unknown intel shows Defenders unknown without fort', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      intel: const CombatModeChoiceIntel(
        role: CombatModeChoiceRole.attacker,
        ownRegimentCount: 3,
        defendersUnknown: true,
      ),
    );
    expect(find.text('Your army: 3 regiments'), findsOneWidget);
    expect(find.text('Defenders unknown'), findsOneWidget);
    expect(find.textContaining('fort'), findsNothing);
    expect(find.textContaining('Open field'), findsNothing);
  });

  testWidgets('defender full intel uses Attackers label not Defenders', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      intel: const CombatModeChoiceIntel(
        role: CombatModeChoiceRole.defender,
        ownRegimentCount: 5,
        enemyRegimentCount: 4,
        fortLevel: 2,
      ),
    );
    expect(find.text('Your army: 5 regiments'), findsOneWidget);
    expect(find.text('Attackers: 4 regiments'), findsOneWidget);
    expect(find.textContaining('Defenders:'), findsNothing);
    expect(find.text('Stone fort siege'), findsOneWidget);
  });

  testWidgets('Details toggle reveals own and enemy type lines', (
    WidgetTester tester,
  ) async {
    await _pump(tester, intel: _attackerFull);
    await tester.tap(find.byType(CtActionTextButton));
    await tester.pump();
    expect(find.textContaining('Musketeers'), findsWidgets);
    expect(find.textContaining('Pikemen'), findsOneWidget);
  });

  testWidgets('owner-absent attacker Details shows own types only', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      detailsInitiallyOpen: true,
      intel: const CombatModeChoiceIntel(
        role: CombatModeChoiceRole.attacker,
        ownRegimentCount: 1,
        ownTypesByRegimentId: {'musketeers': 1},
        fortLevel: 0,
      ),
    );
    expect(find.textContaining('Musketeers'), findsOneWidget);
    expect(find.textContaining('Defenders:'), findsNothing);
    expect(find.text('Open field'), findsOneWidget);
  });

  testWidgets('fail-closed intel omits force lines and still shows meanings', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    expect(find.textContaining('Your army:'), findsNothing);
    expect(find.text('Details'), findsNothing);
    expect(find.text('Decides the battle at once.'), findsOneWidget);
    expect(find.text('You give orders in the fight.'), findsOneWidget);
  });

  testWidgets('capital siege omits Auto-Resolve meaning and keeps fort line', (
    WidgetTester tester,
  ) async {
    await _pump(tester, isCapitalSiege: true, intel: _attackerFull);
    expect(find.textContaining('Auto-Resolve'), findsNothing);
    expect(find.text('Decides the battle at once.'), findsNothing);
    expect(find.text('You give orders in the fight.'), findsOneWidget);
    expect(find.text('Wood fort siege'), findsOneWidget);
    expect(find.textContaining('Quick Battle'), findsWidgets);
  });

  testWidgets('underfed warning remains with force lines', (
    WidgetTester tester,
  ) async {
    const warning =
        'Your armies are short on rations — they will fight somewhat weaker this turn.';
    await _pump(tester, intel: _attackerFull, warning: warning);
    expect(find.text(warning), findsOneWidget);
    expect(find.textContaining('Auto-Resolve'), findsOneWidget);
    expect(find.textContaining('Quick Battle'), findsOneWidget);
  });
}
