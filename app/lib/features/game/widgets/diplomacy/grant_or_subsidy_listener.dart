// Listens for GrantOrSubsidySubmittedEvent and stages the pending order.
// SPEC: SPEC/ui/grant-or-subsidy-dialog.md (DIPL20001 Submit; Refs #4415).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/subscription_tracker.dart';

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
          final order = DiplomaticOrder(
            type: event.isSubsidy
                ? DiplomaticOrderType.setSubsidy
                : DiplomaticOrderType.grantAid,
            targetFactionId: event.targetFactionId,
            amount: event.amount,
          );
          widget.bus.emit(
            AppendDiplomaticOrderRequestedEvent(
              playerId: widget.humanPlayerId,
              order: order,
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
              seed: base ^ (turn * kDeterministicHashMixPrime32) ^ event.amount,
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
