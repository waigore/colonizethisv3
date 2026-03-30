// Listens for GrantOrSubsidySubmittedEvent and shows a confirmation dialog.

import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

class GrantOrSubsidyListener extends StatefulWidget {
  const GrantOrSubsidyListener({
    super.key,
    required this.bus,
    required this.game,
    required this.humanPlayerId,
    required this.child,
  });

  final AppEventBus bus;
  final Game game;
  final String humanPlayerId;
  final Widget child;

  @override
  State<GrantOrSubsidyListener> createState() => _GrantOrSubsidyListenerState();
}

class _GrantOrSubsidyListenerState extends State<GrantOrSubsidyListener> {
  StreamSubscription? _sub;

  String _targetName(String factionId) {
    final p = widget.game.playerById(factionId);
    if (p != null) return p.displayName;
    for (final m in widget.game.minorNations) {
      if (m.id == factionId) return m.displayName ?? factionId;
    }
    for (final t in widget.game.tribes) {
      if (t.id == factionId) return t.displayName ?? factionId;
    }
    return factionId;
  }

  @override
  void initState() {
    super.initState();
    _sub = widget.bus.on<GrantOrSubsidySubmittedEvent>().listen((event) {
      final targetName = _targetName(event.targetFactionId);
      final actionName = event.isSubsidy ? 'Set subsidy' : 'Grant aid';
      widget.bus.emit(
        ConfirmDialogEvent(
          title: actionName,
          message: '$actionName of £${event.amount} to $targetName?',
          onResult: (confirmed) {
            if (confirmed) {
              final orderType = event.isSubsidy
                  ? DiplomaticOrderType.setSubsidy
                  : DiplomaticOrderType.grantAid;
              widget.bus.emit(
                AppendDiplomaticOrderRequestedEvent(
                  playerId: widget.humanPlayerId,
                  order: DiplomaticOrder(
                    type: orderType,
                    targetFactionId: event.targetFactionId,
                    amount: event.amount,
                  ),
                ),
              );
            }
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
