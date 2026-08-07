// Full-screen Counsel screen. SPEC/ui/counsel-panel.md (Refs #4190 / #4191 / #4282).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show rankIndustryCounselRecommendations;
import 'package:colonizethis_logic/trade_counsel_api.dart'
    show rankTradeCounselRecommendationsForHuman;
import 'package:colonizethis_models/colonizethis_models.dart';
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
import 'counsel_industry_apply.dart';
import 'counsel_industry_tab_body.dart';
import 'counsel_trade_apply.dart';
import 'counsel_trade_tab_body.dart';

enum CounselTab { industry, trade }

CounselTab counselTabFromRouteArg(Object? value) {
  if (value == 'trade') return CounselTab.trade;
  return CounselTab.industry;
}

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
        return DefaultTabController(
          length: 2,
          initialIndex: initialTab == CounselTab.trade ? 1 : 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                tabs: [
                  Tab(text: l10n.industryCounsel_tabIndustry),
                  Tab(text: l10n.tradeCounsel_tabTrade),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    CounselIndustryTabBody(
                      recommendations: industryRecommendations,
                      highlightRecommendationId: highlightRecommendationId,
                      l10n: l10n,
                      canEdit: canEdit,
                      callbacks: industryCallbacks,
                    ),
                    CounselTradeTabBody(
                      recommendations: tradeCounsel.recommendations,
                      book: tradeCounsel.book,
                      highlightRecommendationId: highlightRecommendationId,
                      l10n: l10n,
                      canEdit: canEdit,
                      callbacks: tradeCallbacks,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
