// Shared MilitaryUnitsPanel widget-test scaffolding (Refs #3730, #4021, #4048).
// Host, ExpansionTile helpers, and ArmySplit bus harness.
// Scenario Games: military_units_panel_test_scenarios.dart.
// SPEC: SPEC/ui/military-units-panel.md; SPEC/program/repo-lint.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart' show applyArmySplit;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';

import 'app_shell_harness.dart';

export 'military_units_panel_test_scenarios.dart';
export 'units_panel_test_shared.dart';

/// Builds the canonical [MilitaryUnitsPanel] host used across the panel's
/// widget tests: editorial-monocle [buildAppShell] > [Scaffold] wrapping the
/// panel. When [bus] is omitted a fresh [AppEventBus] is created so tests that
/// do not need to drive events still get a valid bus.
Widget buildMilitaryPanel({
  required Game game,
  required String humanPlayerId,
  AppEventBus? bus,
  MapTopology? topology,
  Orders draftOrders = const Orders(),
}) {
  return buildPanelScaffoldShell(
    MilitaryUnitsPanel(
      game: game,
      humanPlayerId: humanPlayerId,
      bus: bus ?? AppEventBus.create(),
      topology: topology ?? const MapTopology(),
      draftOrders: draftOrders,
    ),
  );
}

/// Pumps [buildMilitaryPanel] (or an optional prebuilt [widget]) and settles.
///
/// Canonical military panel pump for panel suites — do not re-declare a local
/// `_pumpMilitary` / `pumpMilitary` clone (Refs #4035; twin of
/// [pumpNavalPanel]).
Future<void> pumpMilitaryPanel(
  WidgetTester tester, {
  required Game game,
  required String humanPlayerId,
  AppEventBus? bus,
  MapTopology? topology,
  Orders draftOrders = const Orders(),
  Widget? widget,
}) async {
  await pumpSettledWidget(
    tester,
    widget ??
        buildMilitaryPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: bus,
          topology: topology,
          draftOrders: draftOrders,
        ),
  );
}

/// Taps the first [ExpansionTile] in the tree (if any) and settles, expanding
/// the first army/fleet group so its detail rows render.
Future<void> expandFirstArmyExpansion(WidgetTester tester) async {
  final tiles = find.byType(ExpansionTile);
  if (tiles.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tiles.first);
  await tester.pumpAndSettle();
}

/// Taps every [ExpansionTile] currently in the tree (settling after each) so
/// all army/fleet groups expand and their detail rows render.
Future<void> expandAllArmyExpansions(WidgetTester tester) async {
  final finder = find.byType(ExpansionTile);
  final n = finder.evaluate().length;
  for (var i = 0; i < n; i++) {
    await tester.tap(finder.at(i));
    await tester.pumpAndSettle();
  }
}

/// Tall viewport for army-split interaction tests ([ListView] rows need height).
const Size kArmySplitTestViewport = Size(480, 900);

/// Pumps [ArmySplitTestHarness] inside the canonical editorial-monocle
/// [buildAppShell] > [Scaffold] host at [kArmySplitTestViewport].
Future<void> pumpArmySplitHarness(
  WidgetTester tester, {
  required Game initialGame,
  required String humanPlayerId,
  required AppEventBus bus,
}) {
  return pumpAppShell(
    tester,
    viewport: kArmySplitTestViewport,
    child: Scaffold(
      body: ArmySplitTestHarness(
        initialGame: initialGame,
        humanPlayerId: humanPlayerId,
        bus: bus,
      ),
    ),
    settle: true,
  );
}

/// Applies [ArmySplitRequestedEvent] like `AppEventHandlerScope` and rebuilds
/// the panel with the updated [Game] (widget tests do not mount the full
/// shell). Used by the split-UI tests that drive a real split through the bus.
class ArmySplitTestHarness extends StatefulWidget {
  const ArmySplitTestHarness({
    super.key,
    required this.initialGame,
    required this.humanPlayerId,
    required this.bus,
  });

  final Game initialGame;
  final String humanPlayerId;
  final AppEventBus bus;

  @override
  State<ArmySplitTestHarness> createState() => _ArmySplitTestHarnessState();
}

class _ArmySplitTestHarnessState extends State<ArmySplitTestHarness> {
  late Game _game;
  StreamSubscription<ArmySplitRequestedEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame;
    _sub = widget.bus.on<ArmySplitRequestedEvent>().listen((e) {
      final next = applyArmySplit(
        game: _game,
        playerId: e.humanPlayerId,
        sourceArmyId: e.sourceArmyId,
        unitIdsToMove: e.unitIdsToMove,
      );
      setState(() => _game = next);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MilitaryUnitsPanel(
      game: _game,
      humanPlayerId: widget.humanPlayerId,
      bus: widget.bus,
      topology: const MapTopology(),
      draftOrders: const Orders(),
    );
  }
}
