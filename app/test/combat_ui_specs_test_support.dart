// Shared combat_ui_specs_part* frames (Refs #4013, #4035 / #4117 slice F).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_action_selector.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_deployment_view.dart';

import 'app_shell_harness.dart';

/// Material frame for layout/content pins ([theme] defaults to light).
Widget combatUiSpecsFrame(
  Widget child, {
  ThemeData? theme,
}) =>
    buildAppShell(
      theme: theme ?? ThemeData.light(),
      child: Scaffold(body: child),
    );

/// Editorial-monocle dark frame for palette/token pins.
Widget combatUiSpecsDarkFrame(Widget child) => buildPanelScaffoldShell(child);

QuickBattleInput combatUiSpecsStandardQuickBattleInput() {
  return const QuickBattleInput(
    attackerFactionId: 'gp1',
    defenderFactionId: 'gp2',
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

QuickBattleGroup combatUiSpecsCenterFront({
  required List<String> unitIds,
  int cohesion = 3,
}) =>
    QuickBattleGroup(
      lane: QuickBattleLane.center,
      line: QuickBattleLine.front,
      unitIds: unitIds,
      cohesion: cohesion,
    );

QuickBattleDeploymentView combatUiSpecsDeploymentView({
  List<QuickBattleGroup> attackerGroups = const [],
  List<QuickBattleGroup> defenderGroups = const [],
  String attackerName = 'Attacker',
  String defenderName = 'Defender',
}) =>
    QuickBattleDeploymentView(
      attackerDeployment: QuickBattleDeployment(groups: attackerGroups),
      defenderDeployment: QuickBattleDeployment(groups: defenderGroups),
      attackerName: attackerName,
      defenderName: defenderName,
    );

Future<void> pumpCombatUiSpecsSelector(
  WidgetTester tester, {
  required int cpRemaining,
  required void Function(QuickBattleAction) onActionSelected,
  bool dark = false,
}) {
  final child = QuickBattleActionSelector(
    cpRemaining: cpRemaining,
    onActionSelected: onActionSelected,
  );
  return tester.pumpWidget(
    dark ? combatUiSpecsDarkFrame(child) : combatUiSpecsFrame(child),
  );
}

(AppEventBus, List<CombatMode>) listenCombatUiSpecsModes() {
  final bus = AppEventBus.create();
  final received = <CombatMode>[];
  final sub = bus.on<CombatModeChosenEvent>().listen((e) {
    received.add(e.mode);
  });
  addTearDown(() async {
    await sub.cancel();
  });
  return (bus, received);
}

Future<void> openCombatUiSpecsModeChoice(
  WidgetTester tester, {
  required AppEventBus bus,
  required String provinceName,
  required bool isCapitalSiege,
}) async {
  await tester.pumpWidget(
    combatUiSpecsFrame(
      Builder(
        builder: (ctx) {
          return TextButton(
            child: const Text('open'),
            onPressed: () {
              showDialog<void>(
                context: ctx,
                builder: (_) => CombatModeChoiceDialog(
                  bus: bus,
                  provinceName: provinceName,
                  isCapitalSiege: isCapitalSiege,
                ),
              );
            },
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> pumpDarkCombatUiSpecsModeChoice(
  WidgetTester tester, {
  required String provinceName,
  required bool isCapitalSiege,
}) =>
    tester.pumpWidget(
      combatUiSpecsDarkFrame(
        CombatModeChoiceDialog(
          bus: AppEventBus.create(),
          provinceName: provinceName,
          isCapitalSiege: isCapitalSiege,
        ),
      ),
    );
