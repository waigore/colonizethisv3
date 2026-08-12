// Full-screen Counsel screen. SPEC/ui/counsel-panel.md (Refs #4190 / #4191 / #4282 / #4307).

export 'counsel_screen_tabs.dart' show CounselTab, counselTabFromRouteArg;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show
        rankDevelopmentCounselRecommendations,
        rankIndustryCounselRecommendations,
        rankMilitaryCounselRecommendations,
        rankTradeCounselRecommendationsForHuman;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart' show OrderEngine;
import 'package:colonizethis_turn/colonizethis_turn.dart' show projectOrderEffects;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/routes.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'counsel_development_apply.dart';
import 'counsel_development_tab_body.dart';
import 'counsel_industry_apply.dart';
import 'counsel_industry_tab_body.dart';
import 'counsel_military_apply.dart';
import 'counsel_military_invade_confirm.dart';
import 'counsel_military_tab_body.dart';
import 'counsel_screen_tabs.dart';
import 'counsel_trade_apply.dart';
import 'counsel_trade_tab_body.dart';
import 'military_counsel_l10n.dart';

class CounselScreen extends ConsumerWidget {
  const CounselScreen({
    super.key,
    required this.game,
    required this.humanPlayerId,
    this.highlightRecommendationId,
    this.initialTab = CounselTab.industry,
  });

  /// SPEC/ui/counsel-panel.md — [UiScreenIds.counselScreen].
  static const screenId = UiScreenIds.counselScreen;

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Counsel';

  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_production.png';

  final Game game;
  final String humanPlayerId;
  final String? highlightRecommendationId;
  final CounselTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      topBar: GameFeatureScreenTopBar.build(
        key: const ValueKey<String>('counselScreenTopBar'),
        title: topBarTitle,
        iconAsset: topBarIconAsset,
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        final shell = shellRef.read(shellPlayerContextProvider);
        final sentinel = observeNotDefinedSentinel(shell, 'Counsel');
        if (sentinel != null) return sentinel;
        final currentOrders = shellRef.watch(currentOrdersProvider);
        final canEdit = shell.canMutateViaUi;
        var topology = MapTopology();
        Map<String, TileMapResult> tileMapByRegion = const {};
        final loaded = tryGetGameMapData(
          () => shellRef.watch(gameServiceProvider).getMapData(displayGame.id),
        );
        if (loaded != null) {
          topology = loaded.combinedTopology;
          tileMapByRegion = loaded.tileMapByRegion;
        }
        final l10n = appL10n(context);
        final bus = shellRef.read(appEventBusProvider);
        final industryRecommendations = rankIndustryCounselRecommendations(
          game: displayGame,
          playerId: humanPlayerId,
          currentOrders: currentOrders,
          topology: topology,
          tileMapByRegion: tileMapByRegion,
        );
        final productionAssignments = desiredOutputToAssignments(
          shellRef.watch(productionDesiredOutputProvider),
        );
        final tradeCounsel = rankTradeCounselRecommendationsForHuman(
          game: displayGame,
          playerId: humanPlayerId,
          productionAssignments: productionAssignments,
          currentOrders: currentOrders,
          topology: topology,
          tileMapByRegion: tileMapByRegion,
        );
        final militaryRecommendations = rankMilitaryCounselRecommendations(
          game: displayGame,
          playerId: humanPlayerId,
          currentOrders: currentOrders,
          topology: topology,
        );
        final developmentRecommendations =
            rankDevelopmentCounselRecommendations(
              game: displayGame,
              playerId: humanPlayerId,
              currentOrders: currentOrders,
              topology: topology,
              tileMapByRegion: tileMapByRegion,
            );
        final industryCallbacks = CounselIndustryCallbacks(
          onApplyProduceAllocation: canEdit
              ? () {
                  final currentDesired = shellRef.read(
                    productionDesiredOutputProvider,
                  );
                  final next = industryCounselDesiredOutputAfterProduceAgree(
                    game: displayGame,
                    playerId: humanPlayerId,
                    currentDesired: currentDesired,
                  );
                  shellRef
                      .read(productionDesiredOutputProvider.notifier)
                      .replaceAll(next);
                }
              : null,
          onAgreeTrain: canEdit
              ? (tier) {
                  final orders = shellRef.read(currentOrdersProvider);
                  final next = industryCounselOrdersAfterTrainAgree(
                    currentOrders: orders,
                    playerId: humanPlayerId,
                    tier: tier,
                    game: displayGame,
                    topology: topology,
                  );
                  if (next == null) {
                    bus.emit(
                      ShowSnackBarEvent(
                        message: l10n.industryCounsel_trainAgreeFailed,
                      ),
                    );
                    return;
                  }
                  shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
                }
              : null,
          onOpenDevelopment: canEdit
              ? () {
                  bus.emit(
                    NavigateToRouteEvent(Routes.development, {
                      'game': displayGame,
                      'humanPlayerId': humanPlayerId,
                    }),
                  );
                }
              : null,
        );
        final tradeCallbacks = CounselTradeCallbacks(
          onApplyBook: canEdit && tradeCounsel.book.isNotEmpty
              ? () {
                  final orders = shellRef.read(currentOrdersProvider);
                  final next = tradeCounselOrdersAfterApplyBook(
                    currentOrders: orders,
                    playerId: humanPlayerId,
                    book: tradeCounsel.book,
                  );
                  shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
                }
              : null,
          onAgreeLine: canEdit
              ? (order) {
                  final orders = shellRef.read(currentOrdersProvider);
                  final next = tradeCounselOrdersAfterAgree(
                    currentOrders: orders,
                    playerId: humanPlayerId,
                    order: order,
                  );
                  if (next == null) {
                    bus.emit(
                      ShowSnackBarEvent(message: l10n.tradeCounsel_applyFailed),
                    );
                    return;
                  }
                  shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
                }
              : null,
        );
        final militaryCallbacks = CounselMilitaryCallbacks(
          onAgreeTrain: canEdit
              ? (recommendation) {
                  final unitType = recommendation.unitType;
                  final count = recommendation.count;
                  if (unitType == null || count == null || count <= 0) {
                    return;
                  }
                  final orders = shellRef.read(currentOrdersProvider);
                  final next = militaryCounselOrdersAfterTrainAgree(
                    game: displayGame,
                    playerId: humanPlayerId,
                    currentOrders: orders,
                    topology: topology,
                    unitType: unitType,
                    count: count,
                  );
                  if (next == null) {
                    bus.emit(
                      ShowSnackBarEvent(
                        message: l10n.militaryCounsel_trainAgreeFailed,
                      ),
                    );
                    return;
                  }
                  shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
                }
              : null,
          onAgreeInvade: canEdit
              ? (recommendation) async {
                  final destination =
                      militaryCounselInvadeDestinationForRecommendation(
                        game: displayGame,
                        playerId: humanPlayerId,
                        currentOrders: shellRef.read(currentOrdersProvider),
                        topology: topology,
                        recommendation: recommendation,
                      );
                  if (destination == null) {
                    bus.emit(
                      ShowSnackBarEvent(
                        message: l10n.militaryCounsel_invadeAgreeFailed,
                      ),
                    );
                    return;
                  }
                  if (destination.requiresDeclareWarOnConfirm) {
                    final ownerLabel = militaryCounselOwnerLabel(
                      l10n,
                      displayGame,
                      recommendation,
                    );
                    final ok = await showMilitaryCounselDeclareWarConfirmDialog(
                      context,
                      l10n,
                      ownerLabel,
                    );
                    if (ok != true || !context.mounted) return;
                  }
                  final orders = shellRef.read(currentOrdersProvider);
                  final next = militaryCounselOrdersAfterInvadeAgree(
                    currentOrders: orders,
                    playerId: humanPlayerId,
                    armyId: recommendation.armyId!,
                    destination: destination,
                  );
                  final engine = OrderEngine(
                    initialOrders: next,
                    projector: projectOrderEffects,
                  );
                  final results = engine.validatePlayerOrdersWithContext(
                    displayGame,
                    topology,
                    humanPlayerId,
                  );
                  if (!results.every((r) => r.isAccepted)) {
                    bus.emit(
                      ShowSnackBarEvent(
                        message: l10n.militaryCounsel_invadeAgreeFailed,
                      ),
                    );
                    return;
                  }
                  shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
                }
              : null,
        );
        final developmentCallbacks = CounselDevelopmentCallbacks(
          onAgreeBuildPort: canEdit
              ? (recommendation) {
                  final orders = shellRef.read(currentOrdersProvider);
                  final workOrder = developmentCounselPortWorkOrderAfterAgree(
                    game: displayGame,
                    playerId: humanPlayerId,
                    currentOrders: orders,
                    topology: topology,
                    recommendation: recommendation,
                    tileMapByRegion: tileMapByRegion,
                  );
                  if (workOrder == null) {
                    bus.emit(
                      ShowSnackBarEvent(
                        message: l10n.developmentCounsel_agreeFailed,
                      ),
                    );
                    return;
                  }
                  bus.emit(
                    UpsertPendingCivilianWorkOrderRequestedEvent(
                      playerId: humanPlayerId,
                      workOrder: workOrder,
                    ),
                  );
                }
              : null,
        );
        return CounselScreenTabs(
          initialTab: initialTab,
          l10n: l10n,
          industryRecommendations: industryRecommendations,
          tradeRecommendations: tradeCounsel.recommendations,
          tradeBook: tradeCounsel.book,
          militaryRecommendations: militaryRecommendations,
          militaryGame: displayGame,
          developmentRecommendations: developmentRecommendations,
          highlightRecommendationId: highlightRecommendationId,
          canEdit: canEdit,
          industryCallbacks: industryCallbacks,
          tradeCallbacks: tradeCallbacks,
          militaryCallbacks: militaryCallbacks,
          developmentCallbacks: developmentCallbacks,
        );
      },
    );
  }
}
