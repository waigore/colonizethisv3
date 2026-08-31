// Counsel screen tab strip and bodies. SPEC/ui/counsel-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'counsel_screen_tab_hosts.dart';

enum CounselTab { industry, trade, military, development }

CounselTab counselTabFromRouteArg(Object? value) {
  if (value == 'trade') return CounselTab.trade;
  if (value == 'military') return CounselTab.military;
  if (value == 'development') return CounselTab.development;
  return CounselTab.industry;
}

int counselTabInitialIndex(CounselTab tab) {
  return switch (tab) {
    CounselTab.industry => 0,
    CounselTab.trade => 1,
    CounselTab.military => 2,
    CounselTab.development => 3,
  };
}

class CounselScreenTabs extends StatefulWidget {
  const CounselScreenTabs({
    super.key,
    required this.initialTab,
    required this.l10n,
    required this.displayGame,
    required this.humanPlayerId,
    required this.mapContext,
    required this.highlightRecommendationId,
    required this.canEdit,
  });

  final CounselTab initialTab;
  final AppLocalizations l10n;
  final Game displayGame;
  final String humanPlayerId;
  final CounselPanelMapContext mapContext;
  final String? highlightRecommendationId;
  final bool canEdit;

  @override
  State<CounselScreenTabs> createState() => _CounselScreenTabsState();
}

class _CounselScreenTabsState extends State<CounselScreenTabs> {
  late final Set<int> _visitedTabIndexes = {
    counselTabInitialIndex(widget.initialTab),
  };

  void _markTabVisited(int index) {
    if (_visitedTabIndexes.contains(index)) return;
    setState(() => _visitedTabIndexes.add(index));
  }

  @override
  Widget build(BuildContext context) {
    final initialIndex = counselTabInitialIndex(widget.initialTab);
    return DefaultTabController(
      length: 4,
      initialIndex: initialIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            isScrollable: true,
            onTap: _markTabVisited,
            tabs: [
              Tab(text: widget.l10n.industryCounsel_tabIndustry),
              Tab(text: widget.l10n.tradeCounsel_tabTrade),
              Tab(text: widget.l10n.militaryCounsel_tabMilitary),
              Tab(text: widget.l10n.developmentCounsel_tabDevelopment),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                CounselIndustryTabHost(
                  displayGame: widget.displayGame,
                  humanPlayerId: widget.humanPlayerId,
                  topology: widget.mapContext.topology,
                  tileMapByRegion: widget.mapContext.tileMapByRegion,
                  highlightRecommendationId: widget.highlightRecommendationId,
                  canEdit: widget.canEdit,
                  l10n: widget.l10n,
                  active: _visitedTabIndexes.contains(0),
                ),
                CounselTradeTabHost(
                  displayGame: widget.displayGame,
                  humanPlayerId: widget.humanPlayerId,
                  topology: widget.mapContext.topology,
                  tileMapByRegion: widget.mapContext.tileMapByRegion,
                  highlightRecommendationId: widget.highlightRecommendationId,
                  canEdit: widget.canEdit,
                  l10n: widget.l10n,
                  active: _visitedTabIndexes.contains(1),
                ),
                CounselMilitaryTabHost(
                  displayGame: widget.displayGame,
                  humanPlayerId: widget.humanPlayerId,
                  topology: widget.mapContext.topology,
                  highlightRecommendationId: widget.highlightRecommendationId,
                  canEdit: widget.canEdit,
                  l10n: widget.l10n,
                  active: _visitedTabIndexes.contains(2),
                ),
                CounselDevelopmentTabHost(
                  displayGame: widget.displayGame,
                  humanPlayerId: widget.humanPlayerId,
                  topology: widget.mapContext.topology,
                  tileMapByRegion: widget.mapContext.tileMapByRegion,
                  highlightRecommendationId: widget.highlightRecommendationId,
                  canEdit: widget.canEdit,
                  l10n: widget.l10n,
                  active: _visitedTabIndexes.contains(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
