import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show techById, techDisplayName;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../core/services/app_event_handler/app_event_handler_scope.dart' show turnNewsDialogId;
import '../core/services/subscription_tracker.dart';
import '../providers/app_event_bus_provider.dart';
import '../providers/game_service_provider.dart';
import '../providers/games_provider.dart';
import 'player_turn_events_session_buffer.dart';

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
  final PlayerTurnEventsSessionBuffer _turnEventsBuffer =
      PlayerTurnEventsSessionBuffer();
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
    _trackPlayerTurnEvents(bus);
  }

  void _trackPlayerTurnEvents(AppEventBus bus) {
    void track<T extends GameToUIEvent>(void Function(T) handler) {
      _subscriptions.track(bus.on<T>().listen(handler));
    }

    track<AppCombatResultEvent>(_bufferPlayerTurnEvent);
    track<AppNavalCombatResultEvent>(_bufferPlayerTurnEvent);
    track<AppProvinceCapturedEvent>(_bufferPlayerTurnEvent);
    track<AppDiplomacyChangeEvent>(_bufferPlayerTurnEvent);
    track<AppResearchCompleteEvent>(_bufferPlayerTurnEvent);
    track<AppOrderRejectedEvent>(_bufferPlayerTurnEvent);
    track<AppWorkOrderCompletedEvent>(_bufferPlayerTurnEvent);
    track<AppOverseasProfitCreditedEvent>(_bufferPlayerTurnEvent);
    track<AppMarketTurnSummaryEvent>(_bufferPlayerTurnEvent);
    track<AppEconomyTurnSummaryEvent>(_bufferPlayerTurnEvent);
    track<AppPlayerProvinceDiscoveredEvent>(_bufferPlayerTurnEvent);
    track<AppPlayerSeaZoneDiscoveredEvent>(_bufferPlayerTurnEvent);
    track<AppOvertureAdvancedEvent>(_bufferPlayerTurnEvent);
    track<AppSpyCaughtEvent>(_bufferPlayerTurnEvent);
    track<AppSpyDefectedEvent>(_bufferPlayerTurnEvent);
    track<AppGeneralMedalGainedEvent>(_bufferPlayerTurnEvent);
  }

  void _bufferPlayerTurnEvent(GameToUIEvent event) {
    if (!mounted) {
      return;
    }
    final humanId = _humanPlayerId(ref.read(currentGameProvider));
    if (humanId.isEmpty) {
      return;
    }
    _turnEventsBuffer.add(event, humanId);
  }

  String _humanPlayerId(Game? game) {
    if (game == null) {
      return '';
    }
    for (final player in game.players) {
      if (player.isHuman) {
        return player.id;
      }
    }
    return '';
  }

  TurnNewsCourtSummary _buildCourtSummary(
    List<GameToUIEvent> events,
    String humanId,
    AppLocalizations l10n,
  ) {
    return buildTurnNewsCourtSummary(
      events: events,
      humanPlayerId: humanId,
      labels: TurnNewsCourtSummaryLabels(
        researchFinished: l10n.turnNews_courtResearchFinished,
        researchFinishedMany: l10n.turnNews_courtResearchFinishedMany,
        researchFinishedUnknown: () => l10n.turnNews_courtResearchFinishedUnknown,
        decreeRefused: () => l10n.turnNews_courtDecreeRefused,
        decreesRefused: l10n.turnNews_courtDecreesRefused,
        battleFought: () => l10n.turnNews_courtBattleFought,
        battlesFought: l10n.turnNews_courtBattlesFought,
        marketEconomy: () => l10n.turnNews_courtMarket,
        workFinished: () => l10n.turnNews_courtWorkFinished,
        worksFinished: l10n.turnNews_courtWorksFinished,
      ),
      techDisplayName: techDisplayName,
      isCatalogTech: (techId) => techById(techId) != null,
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
    final committedEvents = _turnEventsBuffer.takeCommitted();
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
      final humanId = _humanPlayerId(reloaded);
      final l10n = lookupAppLocalizations(const Locale('en'));
      final courtSummary = humanId.isEmpty
          ? const TurnNewsCourtSummary.empty()
          : _buildCourtSummary(committedEvents, humanId, l10n);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(appEventBusProvider)
            .emit(
              OpenDialogEvent(turnNewsDialogId, {
                'digest': digest,
                'newTurnNumber': newTurn,
                'courtSummary': courtSummary,
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
    _turnEventsBuffer.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
