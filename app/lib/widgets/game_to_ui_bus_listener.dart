import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/app_event_handler_scope.dart' show turnNewsDialogId;
import '../core/services/subscription_tracker.dart';
import '../providers/app_event_bus_provider.dart';
import '../providers/game_service_provider.dart';
import '../providers/games_provider.dart';

/// Subscribes to [TurnResolutionCompleteEvent] for [gameId] and reloads
/// [currentGameProvider] from [GameService] when the active game matches.
/// SPEC/program/app-event-bus.md (GameToUI) — empire screens subscribe individually.
class GameToUIBusListener extends ConsumerStatefulWidget {
  const GameToUIBusListener({
    super.key,
    required this.gameId,
    required this.child,
  });

  final String gameId;
  final Widget child;

  @override
  ConsumerState<GameToUIBusListener> createState() =>
      _GameToUIBusListenerState();
}

class _GameToUIBusListenerState extends ConsumerState<GameToUIBusListener> {
  final SubscriptionTracker _subscriptions = SubscriptionTracker();
  bool _busSubscriptionsAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_busSubscriptionsAttached) {
      return;
    }
    _busSubscriptionsAttached = true;
    final bus = ref.read(appEventBusProvider);
    _subscriptions.track(
      bus.on<TurnResolutionCompleteEvent>().listen(_onTurnResolutionComplete),
    );
    _subscriptions.track(
      bus.on<NegotiationMoodUpdateEvent>().listen(_onNegotiationMoodUpdate),
    );
  }

  void _onTurnResolutionComplete(TurnResolutionCompleteEvent event) {
    if (!mounted || event.gameId != widget.gameId) {
      return;
    }
    final current = ref.read(currentGameProvider);
    if (current?.id != event.gameId) {
      return;
    }
    final reloaded = ref.read(gameServiceProvider).loadGame(event.gameId);
    if (reloaded == null || !mounted) {
      return;
    }
    ref.read(currentGameProvider.notifier).setGame(reloaded);
    if (event.turnNumber >= 1 &&
        event.turnNewsDigest != null &&
        reloaded.victory == null) {
      final digest = event.turnNewsDigest!;
      final newTurn = event.turnNumber;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(appEventBusProvider)
            .emit(
              OpenDialogEvent(turnNewsDialogId, {
                'digest': digest,
                'newTurnNumber': newTurn,
              }),
            );
      });
    }
  }

  void _onNegotiationMoodUpdate(NegotiationMoodUpdateEvent event) {
    if (!mounted) return;
    final transition = buildNegotiationMoodTransitionEvent(
      leaderId: event.leaderId,
      currentMood: event.currentMood,
      offerQualityDelta: event.offerQualityDelta,
      stallCounter: event.stallCounter,
      seed: event.seed,
      durationMs: event.durationMs,
    );
    if (transition == null) return;
    ref.read(appEventBusProvider).emit(transition);
  }

  @override
  void dispose() {
    _subscriptions.cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
