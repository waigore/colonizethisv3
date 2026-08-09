// Shared panel bus dialog hosts for diplomacy/civilian panel widget tests.
//
// Lives outside `app/test/support/` so panel bus scaffolding does not count
// toward the support LOC ratchet (Refs #4117).

import 'dart:async';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

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
