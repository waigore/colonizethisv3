// Lazy, session-cached tab hosts for `GAME90001` (Refs #4688 Slice 8).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show TradeCounselBookResult;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/counsel_panel_session_cache_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import 'counsel_development_tab_body.dart';
import 'counsel_industry_tab_body.dart';
import 'counsel_military_tab_body.dart';
import 'counsel_screen_callbacks_industry.dart';
import 'counsel_screen_callbacks_military.dart';
import 'counsel_trade_tab_body.dart';

class CounselIndustryTabHost extends ConsumerWidget {
  const CounselIndustryTabHost({
    super.key,
    required this.displayGame,
    required this.humanPlayerId,
    required this.topology,
    required this.tileMapByRegion,
    required this.highlightRecommendationId,
    required this.canEdit,
    required this.l10n,
    required this.active,
  });

  final Game displayGame;
  final String humanPlayerId;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  final String? highlightRecommendationId;
  final bool canEdit;
  final AppLocalizations l10n;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!active) {
      return const SizedBox.shrink();
    }
    final currentOrders = ref.watch(currentOrdersProvider);
    final desiredOutput = ref.watch(productionDesiredOutputProvider);
    final revision = counselPanelSessionRevision(
      game: displayGame,
      orders: currentOrders,
      desiredOutputByRecipe: desiredOutput,
      topology: topology,
    );
    final recommendations = resolveCounselIndustryRecommendations(
      cache: ref.read(counselPanelSessionCacheProvider),
      revision: revision,
      game: displayGame,
      playerId: humanPlayerId,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
    );
    return CounselIndustryTabBody(
      recommendations: recommendations,
      highlightRecommendationId: highlightRecommendationId,
      l10n: l10n,
      canEdit: canEdit,
      callbacks: buildCounselIndustryCallbacks(
        bus: ref.read(appEventBusProvider),
        readCurrentOrders: () => ref.read(currentOrdersProvider),
        replaceCurrentOrders: (next) =>
            ref.read(currentOrdersProvider.notifier).replaceAll(next),
        readProductionDesiredOutput: () =>
            ref.read(productionDesiredOutputProvider),
        replaceProductionDesiredOutput: (next) => ref
            .read(productionDesiredOutputProvider.notifier)
            .replaceAll(next),
        displayGame: displayGame,
        humanPlayerId: humanPlayerId,
        topology: topology,
        l10n: l10n,
        canEdit: canEdit,
      ),
    );
  }
}

class CounselTradeTabHost extends ConsumerWidget {
  const CounselTradeTabHost({
    super.key,
    required this.displayGame,
    required this.humanPlayerId,
    required this.topology,
    required this.tileMapByRegion,
    required this.highlightRecommendationId,
    required this.canEdit,
    required this.l10n,
    required this.active,
  });

  final Game displayGame;
  final String humanPlayerId;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  final String? highlightRecommendationId;
  final bool canEdit;
  final AppLocalizations l10n;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!active) {
      return const SizedBox.shrink();
    }
    final currentOrders = ref.watch(currentOrdersProvider);
    final desiredOutput = ref.watch(productionDesiredOutputProvider);
    final revision = counselPanelSessionRevision(
      game: displayGame,
      orders: currentOrders,
      desiredOutputByRecipe: desiredOutput,
      topology: topology,
    );
    final tradeCounsel = resolveCounselTradeBook(
      cache: ref.read(counselPanelSessionCacheProvider),
      revision: revision,
      game: displayGame,
      playerId: humanPlayerId,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      productionAssignments: desiredOutputToAssignments(desiredOutput),
    );
    return CounselTradeTabBody(
      recommendations: tradeCounsel.recommendations,
      book: tradeCounsel.book,
      highlightRecommendationId: highlightRecommendationId,
      l10n: l10n,
      canEdit: canEdit,
      callbacks: buildCounselTradeCallbacks(
        bus: ref.read(appEventBusProvider),
        readCurrentOrders: () => ref.read(currentOrdersProvider),
        replaceCurrentOrders: (next) =>
            ref.read(currentOrdersProvider.notifier).replaceAll(next),
        humanPlayerId: humanPlayerId,
        l10n: l10n,
        canEdit: canEdit,
        readTradeCounsel: () => tradeCounsel,
      ),
    );
  }
}

class CounselMilitaryTabHost extends ConsumerWidget {
  const CounselMilitaryTabHost({
    super.key,
    required this.displayGame,
    required this.humanPlayerId,
    required this.topology,
    required this.highlightRecommendationId,
    required this.canEdit,
    required this.l10n,
    required this.active,
  });

  final Game displayGame;
  final String humanPlayerId;
  final MapTopology topology;
  final String? highlightRecommendationId;
  final bool canEdit;
  final AppLocalizations l10n;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!active) {
      return const SizedBox.shrink();
    }
    final currentOrders = ref.watch(currentOrdersProvider);
    final desiredOutput = ref.watch(productionDesiredOutputProvider);
    final revision = counselPanelSessionRevision(
      game: displayGame,
      orders: currentOrders,
      desiredOutputByRecipe: desiredOutput,
      topology: topology,
    );
    final recommendations = resolveCounselMilitaryRecommendations(
      cache: ref.read(counselPanelSessionCacheProvider),
      revision: revision,
      game: displayGame,
      playerId: humanPlayerId,
      currentOrders: currentOrders,
      topology: topology,
    );
    return CounselMilitaryTabBody(
      game: displayGame,
      recommendations: recommendations,
      highlightRecommendationId: highlightRecommendationId,
      l10n: l10n,
      canEdit: canEdit,
      callbacks: buildCounselMilitaryCallbacks(
        context: context,
        bus: ref.read(appEventBusProvider),
        readCurrentOrders: () => ref.read(currentOrdersProvider),
        replaceCurrentOrders: (next) =>
            ref.read(currentOrdersProvider.notifier).replaceAll(next),
        displayGame: displayGame,
        humanPlayerId: humanPlayerId,
        topology: topology,
        l10n: l10n,
        canEdit: canEdit,
      ),
    );
  }
}

class CounselDevelopmentTabHost extends ConsumerWidget {
  const CounselDevelopmentTabHost({
    super.key,
    required this.displayGame,
    required this.humanPlayerId,
    required this.topology,
    required this.tileMapByRegion,
    required this.highlightRecommendationId,
    required this.canEdit,
    required this.l10n,
    required this.active,
  });

  final Game displayGame;
  final String humanPlayerId;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  final String? highlightRecommendationId;
  final bool canEdit;
  final AppLocalizations l10n;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!active) {
      return const SizedBox.shrink();
    }
    final currentOrders = ref.watch(currentOrdersProvider);
    final desiredOutput = ref.watch(productionDesiredOutputProvider);
    final revision = counselPanelSessionRevision(
      game: displayGame,
      orders: currentOrders,
      desiredOutputByRecipe: desiredOutput,
      topology: topology,
    );
    final recommendations = resolveCounselDevelopmentRecommendations(
      cache: ref.read(counselPanelSessionCacheProvider),
      revision: revision,
      game: displayGame,
      playerId: humanPlayerId,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
    );
    return CounselDevelopmentTabBody(
      recommendations: recommendations,
      highlightRecommendationId: highlightRecommendationId,
      l10n: l10n,
      canEdit: canEdit,
      callbacks: buildCounselDevelopmentCallbacks(
        bus: ref.read(appEventBusProvider),
        readCurrentOrders: () => ref.read(currentOrdersProvider),
        displayGame: displayGame,
        humanPlayerId: humanPlayerId,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        l10n: l10n,
        canEdit: canEdit,
      ),
    );
  }
}

CounselPanelMapContext resolveCounselPanelMapContext(WidgetRef ref, Game game) {
  var topology = const MapTopology();
  var tileMapByRegion = const <String, TileMapResult>{};
  final loaded = tryGetGameMapData(
    () => ref.watch(gameServiceProvider).getMapData(game.id),
  );
  if (loaded != null) {
    topology = loaded.combinedTopology;
    tileMapByRegion = loaded.tileMapByRegion;
  }
  return CounselPanelMapContext(
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  );
}

final class CounselPanelMapContext {
  const CounselPanelMapContext({
    required this.topology,
    required this.tileMapByRegion,
  });

  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
}
