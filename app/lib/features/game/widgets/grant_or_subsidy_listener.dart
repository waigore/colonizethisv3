// Listens for GrantOrSubsidySubmittedEvent and shows a confirmation dialog.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../core/services/subscription_tracker.dart';

class GrantOrSubsidyListener extends StatefulWidget {
  const GrantOrSubsidyListener({
    super.key,
    required this.bus,
    required this.game,
    required this.humanPlayerId,
    required this.child,
    this.readOnly = false,
  });

  final AppEventBus bus;
  final Game game;
  final String humanPlayerId;
  final Widget child;
  final bool readOnly;

  @override
  State<GrantOrSubsidyListener> createState() => _GrantOrSubsidyListenerState();
}

class _GrantOrSubsidyListenerState extends State<GrantOrSubsidyListener> {
  final SubscriptionTracker _subscriptions = SubscriptionTracker();
  final Map<String, String> _moodByLeaderId = <String, String>{};

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
    _subscriptions.track(
      widget.bus.on<PortraitMoodEvent>().listen((event) {
        _moodByLeaderId[event.leaderId] = event.toMood;
      }),
    );
    if (!widget.readOnly) {
      _subscriptions.track(
        widget.bus.on<GrantOrSubsidySubmittedEvent>().listen((event) {
        final targetName = _targetName(event.targetFactionId);
        final actionName = event.isSubsidy ? 'Set subsidy' : 'Grant aid';
        // Subsidies are a percentage (Refs #3753 R3); grants are a £ amount.
        final amountText =
            event.isSubsidy ? '${event.amount}%' : '£${event.amount}';
        widget.bus.emit(
          ConfirmDialogEvent(
            title: actionName,
            message: '$actionName of $amountText to $targetName?',
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
                final turn = widget.game.worldState.turnState.turnNumber;
                final base = widget.game.globalGameSeed ?? 0;
                final currentMood =
                    _moodByLeaderId[event.targetFactionId] ?? kDefaultMood;
                widget.bus.emit(
                  NegotiationMoodUpdateEvent(
                    leaderId: event.targetFactionId,
                    currentMood: currentMood,
                    offerQualityDelta: event.isSubsidy ? 0.5 : 0.7,
                    stallCounter: 0,
                    seed:
                        base ^
                        (turn * kDeterministicHashMixPrime32) ^
                        event.amount,
                  ),
                );
              }
            },
          ),
        );
      }),
      );
    }
  }

  @override
  void dispose() {
    _subscriptions.cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
