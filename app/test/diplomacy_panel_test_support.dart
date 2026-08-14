// Shared diplomacy/civilian panel bus/dialog hosts (Refs #3847, #4013, #4035).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/providers/games_provider.dart';

import 'app_shell_harness.dart';
import 'panel_bus_dialog_host.dart';

export 'panel_bus_dialog_host.dart'
    show
        CivilianPanelBusDialogHost,
        DiplomacyPanelBusDialogHost,
        PanelBusDialogHost;

/// `pumpAndSettle` hangs here: Flame nine-patch widgets can keep the ticker
/// busy. Bounded pumps flush layout, bus handlers, and dialog routes.
Future<void> pumpDiplomacyPanelBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Dialogs: `showDialog` from async bus listeners + route transition.
/// Tall surface so diplomacy rows and action buttons are on-screen without
/// calling `ensureVisible` (avoids long scroll pump loops on [ListView]).
Future<void> bindDiplomacyTallTestSurface(WidgetTester tester) =>
    bindFixedTestSurface(tester, const Size(800, 4000));

/// Wide test surface for responsive-layout tests where viewport is driven
/// by an inner [MediaQuery] override, not the surface size alone.
Future<void> bindDiplomacyStandardTestSurface(WidgetTester tester) =>
    bindFixedTestSurface(tester, const Size(900, 1600));

/// Canonical [DiplomacyPanel] host for widget tests with bus-driven dialogs.
Widget buildDiplomacyPanel({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
  Orders currentOrders = const Orders(),
  AppEventBus? bus,
}) {
  final panelBus = bus ?? AppEventBus.create();
  final navigatorKey = GlobalKey<NavigatorState>();
  return buildAppShell(
    navigatorKey: navigatorKey,
    child: Scaffold(
      body: DiplomacyPanelBusDialogHost(
        bus: panelBus,
        navigatorKey: navigatorKey,
        child: DiplomacyPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: currentOrders,
          bus: panelBus,
        ),
      ),
    ),
  );
}

/// Bare [DiplomacyPanel] host without [DiplomacyPanelBusDialogHost].
///
/// Use when the suite auto-answers [ConfirmDialogEvent] via a direct bus
/// listener (e.g. `diplomacy_panel_orders_test`) instead of routing confirms
/// through a test AlertDialog (Refs #4013).
Widget buildDiplomacyPanelShell({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
  Orders currentOrders = const Orders(),
  required AppEventBus bus,
}) {
  return buildPanelScaffoldShell(
    DiplomacyPanel(
      game: game,
      humanPlayerId: humanPlayerId,
      topology: topology,
      currentOrders: currentOrders,
      bus: bus,
    ),
  );
}

/// Responsive-layout variant: pins [viewportSize] via inner [MediaQuery].
Widget wrapDiplomacyPanelAtViewport({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
  required Size viewportSize,
  Orders currentOrders = const Orders(),
  AppEventBus? bus,
}) {
  final panelBus = bus ?? AppEventBus.create();
  return buildPanelScaffoldShell(
    DiplomacyPanel(
      game: game,
      humanPlayerId: humanPlayerId,
      topology: topology,
      currentOrders: currentOrders,
      bus: panelBus,
    ),
    viewport: viewportSize,
  );
}

/// Canonical [CivilianUnitsPanel] host used across the three
/// `civilian_units_panel_part*_test.dart` files and row-card chrome suites
/// (Refs #4013, #4035). Composes [buildAppShell] — callers must not redeclare
/// an inline `MaterialApp` for this panel.
Widget buildCivilianPanel({
  required Game game,
  required String humanPlayerId,
  Orders currentOrders = const Orders(),
  Map<String, List<String>> availableWorkTargets = const {},
  AppEventBus? bus,
  bool explorerOnly = false,
  bool builderOnly = false,
  bool engineerOnly = false,
  bool railBuilderOnly = false,
  bool merchantOnly = false,
  String? tileScopeTileKey,
  String? initialSelectedUnitId,
  String? prospectShortcutTargetTileKey,
  String? exploreShortcutTargetTileKey,
  String? buildImprovementShortcutTargetTileKey,
  String? buildRoadShortcutTargetTileKey,
  String? buildRailShortcutTargetTileKey,
  String? purchaseLandShortcutTargetTileKey,
}) {
  final resolvedBus = bus ?? AppEventBus.create();
  final navigatorKey = GlobalKey<NavigatorState>();
  return buildAppShell(
    navigatorKey: navigatorKey,
    overrides: [
      availableWorkTargetIdsForUnitProvider.overrideWith(
        (ref, unitId) => availableWorkTargets[unitId] ?? const [],
      ),
    ],
    child: Scaffold(
      body: CivilianPanelBusDialogHost(
        bus: resolvedBus,
        navigatorKey: navigatorKey,
        child: CivilianUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          bus: resolvedBus,
          tileScopeTileKey: tileScopeTileKey,
          initialSelectedUnitId: initialSelectedUnitId,
          explorerOnly: explorerOnly,
          builderOnly: builderOnly,
          engineerOnly: engineerOnly,
          railBuilderOnly: railBuilderOnly,
          merchantOnly: merchantOnly,
          prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
          exploreShortcutTargetTileKey: exploreShortcutTargetTileKey,
          buildImprovementShortcutTargetTileKey:
              buildImprovementShortcutTargetTileKey,
          buildRoadShortcutTargetTileKey: buildRoadShortcutTargetTileKey,
          buildRailShortcutTargetTileKey: buildRailShortcutTargetTileKey,
          purchaseLandShortcutTargetTileKey: purchaseLandShortcutTargetTileKey,
        ),
      ),
    ),
  );
}

/// Reads the percentage and tier span colors from the [RelativePowerLine]
/// rendered inside the diplomacy row keyed by [factionId]. The line is a
/// `Text.rich` whose root `TextSpan` children are
/// `[prefix, percentage, separator, tier]`.
({Color? pctColor, Color? tierColor}) relativePowerSpanColors(
  WidgetTester tester,
  String factionId,
) {
  final lineFinder = find.descendant(
    of: find.byKey(ValueKey('$kDiplomacyRowBodyKeyPrefix$factionId')),
    matching: find.byType(RelativePowerLine),
  );
  final richText = tester.widget<RichText>(
    find.descendant(of: lineFinder, matching: find.byType(RichText)).first,
  );
  // `Text.rich` nests the supplied root span under the effective-style span
  // that `Text` builds, so the relative-power spans live one level deeper.
  final root = (richText.text as TextSpan).children!.first as TextSpan;
  final children = root.children!;
  final pctSpan = children[1] as TextSpan;
  final tierSpan = children[3] as TextSpan;
  return (pctColor: pctSpan.style?.color, tierColor: tierSpan.style?.color);
}
