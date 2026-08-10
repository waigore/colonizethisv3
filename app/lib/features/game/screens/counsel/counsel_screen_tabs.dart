// Counsel screen tab strip and bodies. SPEC/ui/counsel-panel.md.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/military_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'counsel_industry_tab_body.dart';
import 'counsel_military_tab_body.dart';
import 'counsel_trade_tab_body.dart';

enum CounselTab { industry, trade, military }

CounselTab counselTabFromRouteArg(Object? value) {
  if (value == 'trade') return CounselTab.trade;
  if (value == 'military') return CounselTab.military;
  return CounselTab.industry;
}

int counselTabInitialIndex(CounselTab tab) {
  return switch (tab) {
    CounselTab.industry => 0,
    CounselTab.trade => 1,
    CounselTab.military => 2,
  };
}

class CounselScreenTabs extends StatelessWidget {
  const CounselScreenTabs({
    super.key,
    required this.initialTab,
    required this.l10n,
    required this.industryRecommendations,
    required this.tradeRecommendations,
    required this.tradeBook,
    required this.militaryRecommendations,
    required this.militaryGame,
    required this.highlightRecommendationId,
    required this.canEdit,
    required this.industryCallbacks,
    required this.tradeCallbacks,
    required this.militaryCallbacks,
  });

  final CounselTab initialTab;
  final AppLocalizations l10n;
  final List<IndustryCounselRecommendation> industryRecommendations;
  final List<TradeCounselRecommendation> tradeRecommendations;
  final List<TradeOrder> tradeBook;
  final List<MilitaryCounselRecommendation> militaryRecommendations;
  final Game militaryGame;
  final String? highlightRecommendationId;
  final bool canEdit;
  final CounselIndustryCallbacks industryCallbacks;
  final CounselTradeCallbacks tradeCallbacks;
  final CounselMilitaryCallbacks militaryCallbacks;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: counselTabInitialIndex(initialTab),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.industryCounsel_tabIndustry),
              Tab(text: l10n.tradeCounsel_tabTrade),
              Tab(text: l10n.militaryCounsel_tabMilitary),
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
                  recommendations: tradeRecommendations,
                  book: tradeBook,
                  highlightRecommendationId: highlightRecommendationId,
                  l10n: l10n,
                  canEdit: canEdit,
                  callbacks: tradeCallbacks,
                ),
                CounselMilitaryTabBody(
                  game: militaryGame,
                  recommendations: militaryRecommendations,
                  highlightRecommendationId: highlightRecommendationId,
                  l10n: l10n,
                  canEdit: canEdit,
                  callbacks: militaryCallbacks,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
