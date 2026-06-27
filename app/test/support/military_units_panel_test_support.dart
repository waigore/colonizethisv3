// Shared widget-test scaffolding for the `MilitaryUnitsPanel` test family.
//
// The six `app/test/military_units_panel_part*_test.dart` files each previously
// re-declared an identical local `buildPanel(...)` closure (a plain
// `MaterialApp` > `Scaffold` host for `MilitaryUnitsPanel`), identical
// `expandFirstArmyExpansion` / `expandAllArmyExpansions` `ExpansionTile`
// helpers, and a byte-identical `_ArmySplitTestHarness` widget that mirrors the
// running shell's `ArmySplitRequestedEvent` handling. Consolidating them here
// keeps each part file's per-test fixtures and assertions local while removing
// the copy-pasted shell, tree helpers, and bus wiring.
//
// Refs #3730 (consolidate app test scaffolding; partN shared setup).
// SPEC: SPEC/ui/military-units-panel.md (panel behavior under test),
// SPEC/program/repo-lint.md (test static-analysis scope).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart' show applyArmySplit;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';

/// Builds the canonical [MilitaryUnitsPanel] host used across the panel's
/// widget tests: a plain [MaterialApp] > [Scaffold] wrapping the panel. When
/// [bus] is omitted a fresh [AppEventBus] is created so tests that do not need
/// to drive events still get a valid bus.
Widget buildMilitaryPanel({
  required Game game,
  required String humanPlayerId,
  AppEventBus? bus,
  MapTopology? topology,
  Orders draftOrders = const Orders(),
}) {
  return MaterialApp(
    home: Scaffold(
      body: MilitaryUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: bus ?? AppEventBus.create(),
        topology: topology ?? const MapTopology(),
        draftOrders: draftOrders,
      ),
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
