// Shared diplomacy/civilian panel bus/dialog hosts (Refs #3847, #4013, #4035).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/providers/games_provider.dart';

import 'app_shell_harness.dart';

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

/// Shared panel bus dialog leaf (Refs #4035).
///
/// Listens for [ConfirmDialogEvent] (always) and optionally [OpenDialogEvent]
/// / [ClosePanelEvent], routing them through [navigatorKey]. When
/// [deferDialogsWithMicrotask] is true, `showDialog` is scheduled past the
/// pointer + emit stack so tests do not hang the binding (diplomacy path).
class PanelBusDialogHost extends StatefulWidget {
  const PanelBusDialogHost({
    super.key,
    required this.bus,
    required this.child,
    required this.navigatorKey,
    this.handleOpenDialog = false,
    this.handleClosePanel = false,
    this.deferDialogsWithMicrotask = false,
  });

  final AppEventBus bus;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool handleOpenDialog;
  final bool handleClosePanel;
  final bool deferDialogsWithMicrotask;

  @override
  State<PanelBusDialogHost> createState() => _PanelBusDialogHostState();
}

class _PanelBusDialogHostState extends State<PanelBusDialogHost> {
  StreamSubscription? _confirmSub;
  StreamSubscription? _openDialogSub;
  StreamSubscription? _closeSub;

  Future<void> _showConfirm(ConfirmDialogEvent event) async {
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
  }

  Future<void> _showOpenDialog(OpenDialogEvent event) async {
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
  }

  void _runDialogWork(Future<void> Function() work) {
    if (widget.deferDialogsWithMicrotask) {
      scheduleMicrotask(() async {
        await work();
      });
      return;
    }
    unawaited(work());
  }

  @override
  void initState() {
    super.initState();
    _confirmSub = widget.bus.on<ConfirmDialogEvent>().listen((event) {
      _runDialogWork(() => _showConfirm(event));
    });
    if (widget.handleOpenDialog) {
      _openDialogSub = widget.bus.on<OpenDialogEvent>().listen((event) {
        _runDialogWork(() => _showOpenDialog(event));
      });
    }
    if (widget.handleClosePanel) {
      _closeSub = widget.bus.on<ClosePanelEvent>().listen((_) {
        widget.navigatorKey.currentState?.maybePop();
      });
    }
  }

  @override
  void dispose() {
    _confirmSub?.cancel();
    _openDialogSub?.cancel();
    _closeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Diplomacy panel bus host: confirm + open-dialog leaves with microtask defer.
class DiplomacyPanelBusDialogHost extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PanelBusDialogHost(
      bus: bus,
      navigatorKey: navigatorKey,
      handleOpenDialog: true,
      deferDialogsWithMicrotask: true,
      child: child,
    );
  }
}

/// Civilian panel bus host: confirm dialog + [ClosePanelEvent] pop.
class CivilianPanelBusDialogHost extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PanelBusDialogHost(
      bus: bus,
      navigatorKey: navigatorKey,
      handleClosePanel: true,
      child: child,
    );
  }
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
  return buildAppShell(
    child: Scaffold(
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
  return buildAppShell(
    viewport: viewportSize,
    child: Scaffold(
      body: DiplomacyPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        topology: topology,
        currentOrders: currentOrders,
        bus: panelBus,
      ),
    ),
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
  String? tileScopeTileKey,
  String? initialSelectedUnitId,
  String? prospectShortcutTargetTileKey,
  String? exploreShortcutTargetTileKey,
  String? buildImprovementShortcutTargetTileKey,
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
          prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
          exploreShortcutTargetTileKey: exploreShortcutTargetTileKey,
          buildImprovementShortcutTargetTileKey:
              buildImprovementShortcutTargetTileKey,
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
