// Shared widget-test scaffolding for diplomacy and civilian panel bus/dialog
// hosts. Refs #3847, #4013.
//
// Diplomacy tests previously duplicated `_EventHandlingWrapper`,
// `_pumpPanelBuilt`, and `_bindTallTestSurface` across multiple files.
// Civilian panel tests duplicated a related bus host with
// [ClosePanelEvent] handling, plus an identical local `buildPanel` closure
// across `civilian_units_panel_part*_test.dart` (consolidated as
// [buildCivilianPanel]).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/providers/games_provider.dart';

/// `pumpAndSettle` hangs here: Flame nine-patch widgets can keep the ticker
/// busy. Bounded pumps flush layout, bus handlers, and dialog routes.
Future<void> pumpDiplomacyPanelBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Dialogs: `showDialog` from async bus listeners + route transition.
/// Tall surface so diplomacy rows and action buttons are on-screen without
/// calling `ensureVisible` (avoids long scroll pump loops on [ListView]).
Future<void> bindDiplomacyTallTestSurface(WidgetTester tester) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(800, 4000));
}

/// Wide test surface for responsive-layout tests where viewport is driven
/// by an inner [MediaQuery] override, not the surface size alone.
Future<void> bindDiplomacyStandardTestSurface(WidgetTester tester) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(900, 1600));
}

/// Listens for [ConfirmDialogEvent] and [OpenDialogEvent] on [bus] and routes
/// them through [navigatorKey], deferring `showDialog` past the pointer +
/// emit stack so tests do not hang the binding.
class DiplomacyPanelBusDialogHost extends StatefulWidget {
  const DiplomacyPanelBusDialogHost({
    super.key,
    required this.bus,
    required this.child,
    required this.navigatorKey,
  });

  final AppEventBus bus;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<DiplomacyPanelBusDialogHost> createState() =>
      _DiplomacyPanelBusDialogHostState();
}

class _DiplomacyPanelBusDialogHostState
    extends State<DiplomacyPanelBusDialogHost> {
  StreamSubscription? _confirmSub;
  StreamSubscription? _openDialogSub;

  @override
  void initState() {
    super.initState();
    _confirmSub = widget.bus.on<ConfirmDialogEvent>().listen((event) {
      scheduleMicrotask(() async {
        if (!mounted) return;
        final nav = widget.navigatorKey.currentState;
        if (nav == null) return;
        final result = await showDialog<bool>(
          context: nav.context,
          builder: (ctx) => AlertDialog(
            title: Text(event.title),
            content: Text(event.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(event.cancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(event.confirmLabel),
              ),
            ],
          ),
        );
        event.result(result ?? false);
      });
    });
    _openDialogSub = widget.bus.on<OpenDialogEvent>().listen((event) {
      scheduleMicrotask(() async {
        if (!mounted) return;
        final nav = widget.navigatorKey.currentState;
        if (nav == null) return;
        await showDialog<void>(
          context: nav.context,
          builder: (ctx) => AlertDialog(
            title: Text('dialog:${event.dialogId}'),
            content: const Text('opened-via-bus'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _confirmSub?.cancel();
    _openDialogSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Civilian panel bus host: [ClosePanelEvent] pops the navigator and
/// [ConfirmDialogEvent] opens a confirmation dialog.
class CivilianPanelBusDialogHost extends StatefulWidget {
  const CivilianPanelBusDialogHost({
    super.key,
    required this.bus,
    required this.child,
    required this.navigatorKey,
  });

  final AppEventBus bus;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<CivilianPanelBusDialogHost> createState() =>
      _CivilianPanelBusDialogHostState();
}

class _CivilianPanelBusDialogHostState
    extends State<CivilianPanelBusDialogHost> {
  StreamSubscription? _confirmSub;
  StreamSubscription? _closeSub;

  @override
  void initState() {
    super.initState();
    _closeSub = widget.bus.on<ClosePanelEvent>().listen((_) {
      widget.navigatorKey.currentState?.maybePop();
    });
    _confirmSub = widget.bus.on<ConfirmDialogEvent>().listen((event) async {
      final nav = widget.navigatorKey.currentState;
      if (nav == null) return;
      final result = await showDialog<bool>(
        context: nav.context,
        builder: (ctx) => AlertDialog(
          title: Text(event.title),
          content: Text(event.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(event.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(event.confirmLabel),
            ),
          ],
        ),
      );
      event.result(result ?? false);
    });
  }

  @override
  void dispose() {
    _confirmSub?.cancel();
    _closeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
  return MaterialApp(
    navigatorKey: navigatorKey,
    home: Scaffold(
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
  return MaterialApp(
    home: Scaffold(
      body: DiplomacyPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        topology: topology,
        currentOrders: currentOrders,
        bus: bus,
      ),
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
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: viewportSize),
      child: Scaffold(
        body: DiplomacyPanel(
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

/// Canonical [CivilianUnitsPanel] host used across the three
/// `civilian_units_panel_part*_test.dart` files (Refs #4013).
Widget buildCivilianPanel({
  required Game game,
  required String humanPlayerId,
  Orders currentOrders = const Orders(),
  Map<String, List<String>> availableWorkTargets = const {},
  AppEventBus? bus,
  bool explorerOnly = false,
  bool builderOnly = false,
  String? prospectShortcutTargetTileKey,
  String? exploreShortcutTargetTileKey,
  String? buildImprovementShortcutTargetTileKey,
}) {
  final resolvedBus = bus ?? AppEventBus.create();
  final navigatorKey = GlobalKey<NavigatorState>();
  return ProviderScope(
    overrides: [
      availableWorkTargetIdsForUnitProvider.overrideWith(
        (ref, unitId) => availableWorkTargets[unitId] ?? const [],
      ),
    ],
    child: MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: CivilianPanelBusDialogHost(
          bus: resolvedBus,
          navigatorKey: navigatorKey,
          child: CivilianUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: currentOrders,
            bus: resolvedBus,
            explorerOnly: explorerOnly,
            builderOnly: builderOnly,
            prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
            exploreShortcutTargetTileKey: exploreShortcutTargetTileKey,
            buildImprovementShortcutTargetTileKey:
                buildImprovementShortcutTargetTileKey,
          ),
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
