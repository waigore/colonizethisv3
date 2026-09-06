part of 'app_localizations_en.dart';

mixin _AppLocalizationsEnStrings3 on AppLocalizations {
  @override
  String get development_purchasedLand => 'Purchased land';

  @override
  String get development_noImprovableResources => 'No improvable resources';

  @override
  String development_noMatchForInboundCommodity(String name) =>
      'No improvable land for $name';

  @override
  String get development_materialsShortageForAssign =>
      'Materials shortage for assign:';

  @override
  String development_idleCivilians(int builders, int engineers) {
    return 'Idle Builders: $builders · Idle Engineers: $engineers';
  }

  @override
  String get development_assignedCiviliansHeading => 'Assigned civilians';

  @override
  String get development_mapDataUnavailable => 'Map data unavailable';

  @override
  String get development_disconnectedTitle => 'Not connected to capital';

  @override
  String get development_disconnectedBody =>
      'The chosen tile is not linked to your capital. Improve anyway, build a road step toward the capital first, or cancel.';

  @override
  String get development_roadFirst => 'Road first';

  @override
  String get development_improveAnyway => 'Improve anyway';

  @override
  String get development_show => 'Show';

  @override
  String development_improvableCount(int count, String name) {
    return '$count $name';
  }

  @override
  String get production_breakdown_title => 'Commodity breakdown';

  @override
  String get production_breakdown_commodity => 'Commodity';

  @override
  String get production_breakdown_total => 'Total';

  @override
  String get production_breakdown_phase_pendingBuildCosts =>
      'Pending build costs';

  @override
  String get production_breakdown_phase_extraction => 'Extraction';

  @override
  String get production_breakdown_phase_richesToTreasury =>
      'Riches to treasury';

  @override
  String get production_breakdown_phase_consumption => 'Consumption';

  @override
  String get production_breakdown_phase_production => 'Production';

  @override
  String get production_breakdown => 'Breakdown';

  @override
  String get production_counsel => 'Counsel';

  @override
  String production_industryCounselStarSemantic(String brief) {
    return 'Industry counsel: $brief';
  }

  @override
  String get industryCounsel_tabIndustry => 'Industry';

  @override
  String get industryCounsel_empty => 'No pressing industry advice this turn.';

  @override
  String get industryCounsel_title_produce => 'Produce goods';

  @override
  String industryCounsel_title_produceRecipe(String commodity) {
    return 'Produce $commodity';
  }

  @override
  String get industryCounsel_title_train => 'Train workers';

  @override
  String industryCounsel_title_trainWorker(String tier) {
    return 'Train $tier';
  }

  @override
  String get industryCounsel_title_feedstock => 'Unblock feedstock';

  @override
  String industryCounsel_title_unblockFeedstock(String commodity) {
    return 'Improve $commodity extraction';
  }

  @override
  String get industryCounsel_reason_outputShortage_brief =>
      'Your stocks of this output are low — the plan favours producing it now.';

  @override
  String get industryCounsel_reason_outputShortage_detail =>
      'Short output stocks raise the priority of this recipe in the neutral industry plan.';

  @override
  String get industryCounsel_reason_chainLuxury_brief =>
      'This output feeds training or downstream industry — worth prioritising.';

  @override
  String get industryCounsel_reason_chainLuxury_detail =>
      'Chain outputs and worker luxuries score higher when your workforce can use them.';

  @override
  String get industryCounsel_reason_labourDeficit_brief =>
      'Recruit peasants — planned labour exceeds effective workers.';

  @override
  String get industryCounsel_reason_labourDeficit_detail =>
      'The core allocation assigns more labour than your effective pool can supply this turn.';

  @override
  String get industryCounsel_reason_luxuryShortage_brief =>
      'Train this tier — luxury goods for them are scarce.';

  @override
  String get industryCounsel_reason_luxuryShortage_detail =>
      'Soft luxury caps favour training when refined luxuries are below sustainable levels.';

  @override
  String get industryCounsel_reason_feedstockBlocked_brief =>
      'Improve feedstock tiles to unblock starred production inputs.';

  @override
  String get industryCounsel_reason_feedstockBlocked_detail =>
      'Production is input-starved while improvable tiles can raise the blocking commodity.';

  @override
  String get industryCounsel_action_applyProduceAllocation =>
      'Apply recommended industry allocation';

  @override
  String get industryCounsel_action_agreeTrain => 'Agree';

  @override
  String get industryCounsel_action_openDevelopment => 'Open Development';

  @override
  String get industryCounsel_trainAgreeFailed =>
      'Cannot train that worker tier right now — check stockpile and queued orders.';

  @override
  String get tradeCounsel_tabTrade => 'Trade';

  @override
  String get tradeCounsel_empty => 'No pressing market advice this turn.';

  @override
  String get tradeCounsel_action_applyBook => 'Apply recommended market book';

  @override
  String get tradeCounsel_action_agree => 'Agree';

  @override
  String get tradeCounsel_applyFailed =>
      'Cannot apply that market advice right now — check caps and treasury.';

  @override
  String tradeCounsel_title_bid(String commodity, int quantity) {
    return 'Bid $commodity × $quantity';
  }

  @override
  String tradeCounsel_title_offer(String commodity, int quantity) {
    return 'Offer $commodity × $quantity';
  }

  @override
  String get tradeCounsel_reason_surplusAboveReserve_brief =>
      'Sell surplus above your reserve — the planner would offer this stock.';

  @override
  String get tradeCounsel_reason_industryShortage_brief =>
      'Buy below production cost — industry inputs are short.';

  @override
  String get tradeCounsel_reason_speculativeInventory_brief =>
      'Affluent treasury — build stock toward the planner target.';

  @override
  String get tradeMarket_counsel => 'Counsel';

  @override
  String tradeMarket_tradeCounselStarSemantic(String brief) {
    return 'Trade counsel: $brief';
  }

  @override
  String get tradeMarket_firstRightChip => 'First right';

  @override
  String get tradeMarket_firstRightTooltip =>
      'You hold first right on goods from this purchased tile. Your bids clear '
      'before rivals, and you earn overseas profit when another power buys here.';

  @override
  String get tradeMarket_lastMarketChip => 'Last market';

  @override
  String tradeMarket_lastMarketTooltip(int bought, int sold) =>
      'Last market: $bought bought · $sold sold worldwide. This is not your staged Bid or Offer.';

  @override
  String get tradeMarket_priceMovedTooltip =>
      "Last market moved this price. This turn's deals use the price shown.";

  @override
  String get tradeDealBook_matchTagFirstRight => 'First right';

  @override
  String get tradeDealBook_matchTagFavoredPartner => 'Favored partner';

  @override
  String get tradeDealBook_overseasProfitHeading => 'Overseas profit';

  @override
  String tradeDealBook_overseasProfitRow(
    String commodity,
    int quantity,
    int amount,
  ) => '$commodity × $quantity — £$amount credited';

  @override
  String eventFeed_overseasProfitCredited(int amount, int count) =>
      'Overseas profit credited: £$amount from $count rival purchase(s). '
      'Tap to open Deal Book.';

  @override
  String get production_available => 'Available';

  @override
  String get production_availableSellableTooltip =>
      'How many you can still sell after industry reservations and offers '
      'already staged. Tap to open Trade.';

  @override
  String production_availableOpenTradeSemantic(String name) =>
      'Open Trade for $name';

  @override
  String production_affordanceOpenDevelopmentSemantic(String name) =>
      'Open Development for $name';

  @override
  String get production_food => 'Food';

  @override
  String get production_rawMaterials => 'Raw Materials';

  @override
  String get production_manufactured => 'Manufactured';

  @override
  String get production_workers => 'Workers';

  @override
  String get production_workers_peasants => 'Peasants';

  @override
  String get production_workers_apprentices => 'Apprentices';

  @override
  String get production_workers_journeymen => 'Journeymen';

  @override
  String get production_workers_masters => 'Masters';

  @override
  String get production_allocation => 'Allocation';

  @override
  String get production_allocationDecrementRecipe =>
      'Decrease desired output for this recipe';

  @override
  String get production_allocationIncrementRecipe =>
      'Increase desired output for this recipe';

  @override
  String get production_allocationMaximizeRecipe =>
      'Set this recipe to maximum desired output';

  @override
  String get production_allocationClearRecipe =>
      'Clear desired output for this recipe';

  @override
  String get splitArmy_title => 'Split Army';

  @override
  String technologyPanel_title(String playerName) {
    return 'Technology - $playerName';
  }

  @override
  String technologyPanel_researchSlotsCount(int slots) {
    return 'Research slots: $slots';
  }

  @override
  String get technologyPanel_researchSlots => 'Research slots';

  @override
  String get technologyPanel_empty => 'Empty';

  @override
  String technologyPanel_slot(int slot) {
    return 'Slot $slot';
  }

  @override
  String technologyPanel_slotSubtitle(
    String name,
    int progress,
    String costLabel,
  ) {
    return '$name - $progress/$costLabel RP';
  }

  @override
  String get technologyPanel_noTechAssigned => 'No tech assigned';

  @override
  String get technologyPanel_chooseTech => 'Choose tech';

  @override
  String technologyPanel_researched(int count) {
    return 'Researched ($count):';
  }

  @override
  String get technologyPanel_noneYet => 'None yet';

  @override
  String get technologyPanel_inProgress => 'In progress:';

  @override
  String technologyPanel_progressLine(String name, int points) {
    return '$name: $points RP';
  }

  @override
  String get technologyPanel_noTechsAvailable =>
      'No techs available to research';

  @override
  String get technologyPanel_researchedTechsHeading => 'Researched Techs';

  @override
  String get technologyPanel_researchSlotsHeading => 'Research Slots';

  @override
  String technologyPanel_lockedSlotLabel(int slot) {
    return 'Slot $slot (University)';
  }

  @override
  String get technologyPanel_lockedSlotFootnote => 'Requires University tech';

  @override
  String technologyPanel_slotRpProgress(int progress, int cost) {
    return '$progress / $cost RP';
  }

  @override
  String technologyPanel_pickSubtitle(String era, String category, int cost) {
    return 'Era $era - $category - $cost RP';
  }

  @override
  String technologyPanel_chooseTechDialogTitle(int slot) {
    return 'Choose Tech \u2014 Slot $slot';
  }

  @override
  String get technologyPanel_chooseTechDetails => 'Details';

  @override
  String get technologyPanel_slotCancelled => 'Research slot cancelled';

  @override
  String get technologyPanel_cancelWarningTitle => 'Forfeit research progress?';

  @override
  String technologyPanel_cancelWarningMessage(String name, int points) {
    return 'Cancelling this slot forfeits $points RP of progress on $name. '
        'This cannot be undone.';
  }

  @override
  String get technologyPanel_cancelWarningConfirm => 'Forfeit';

  @override
  String get technologyPanel_cancelWarningKeep => 'Keep researching';

  @override
  String get technologyPanel_fundingNone => 'None';

  @override
  String get technologyPanel_fundingLow => 'Low';

  @override
  String get technologyPanel_fundingMedium => 'Medium';

  @override
  String get technologyPanel_fundingHigh => 'High';

  @override
  String get technologyPanel_fundingMaximum => 'Maximum';

  @override
  String technologyPanel_rpDeltaPreview(int rp) {
    return '+$rp RP';
  }

  @override
  String technologyPanel_goldSpendPerTurn(int gold) {
    return '\u2212$gold/turn';
  }

  @override
  String technologyPanel_goldNoSpendPerTurn(int gold) {
    return '$gold/turn';
  }

  @override
  String get technologyPanel_rpBreakdownTitle => 'Research points this turn';

  @override
  String technologyPanel_rpBreakdownBaseLabel(String funding) {
    return 'Base \u2014 $funding funding';
  }

  @override
  String get technologyPanel_rpBreakdownIndustrialLabel =>
      'Industrial Funding +20%';

  @override
  String technologyPanel_rpBreakdownSpyInsightOne(String court) {
    return 'Spy insight \u2014 $court already knows this (+15%)';
  }

  @override
  String technologyPanel_rpBreakdownSpyInsightMany(String courts, int percent) {
    return 'Spy insight \u2014 $courts already know this (+$percent%)';
  }

  @override
  String get technologyPanel_rpBreakdownEffectiveLabel =>
      'Effective RP this turn';

  @override
  String get technologyPanel_rpBreakdownTreasuryLabel =>
      'Treasury cost this turn';

  @override
  String get technologyPanel_rpBreakdownDebtBlocked =>
      'Treasury below the research debt floor \u2014 0 RP applied this turn.';

  @override
  String technologyPanel_rpValue(int rp) {
    return '$rp RP';
  }

  @override
  String technologyPanel_goldValue(int gold) {
    return '$gold gold';
  }

  @override
  String get techTree_noTechsInCatalog => 'No techs in catalog';

  @override
  String techTree_eraCategory(String era, String category) {
    return 'Era $era - $category';
  }

  @override
  String techTree_researchPoints(int points) {
    return '$points RP';
  }

  @override
  String get techTree_prerequisites => 'Prerequisites';

  @override
  String get techTree_effects => 'Effects';

  @override
  String get techTree_legendTitle => 'Technology tree legend';

  @override
  String get techTree_stateResearched => 'Researched';

  @override
  String get techTree_stateInProgress => 'In progress';

  @override
  String get techTree_stateAvailable => 'Available';

  @override
  String get techTree_stateLocked => 'Locked';

  @override
  String get techTree_researchedBy => 'Researched by';

  @override
  String get techTree_legendGpPennants =>
      'GP nation-color pennants (highlighted = you)';

  @override
  String get techTree_researchersDialogTitle => 'Researched by';

  @override
  String get techTree_researchThis => 'Research this';

  @override
  String get techTree_replaceSeatPrompt => 'Replace a research seat';

  @override
  String techTree_replaceSeatLabel(int slot, String tech) =>
      'Slot $slot — $tech';

  @override
  String get techTree_assignReasonObserveOnly =>
      'Research seats cannot be changed while observing.';

  @override
  String get techTree_assignReasonAlreadyKnown =>
      'You already know this technology.';

  @override
  String techTree_assignReasonAlreadySeated(int slot) =>
      'Already researching in Slot $slot.';

  @override
  String techTree_assignReasonWaitingOn(String names) => 'Waiting on: $names';

  @override
  String get techTree_assignReasonDiscovery =>
      'Requires discovering a related resource first.';

  @override
  String get mapDebug_fullVisibility => 'Full visibility';

  @override
  String get mapDebug_playerConstrained => 'Player-constrained';

  @override
  String get mapDebug_hideProvinceNames => 'No province names';

  @override
  String get mapDebug_noNames => 'No names';

  @override
  String get widgetbook_primaryAction => 'Primary action';

  @override
  String get widgetbook_disabled => 'Disabled';

  @override
  String get widgetbook_fixedWidth => 'Fixed width';

  @override
  String get widgetbook_noPlayers => 'No players';

  @override
  String get widgetbook_techTreeTitle => 'Tech Tree';

  @override
  String get widgetbook_openBreakdownDialog => 'Open breakdown dialog';

  @override
  String get widgetbook_gameShell => 'Game shell';

  @override
  String techTree_bulletItem(String text) {
    return '- $text';
  }

  @override
  String get provinceOverlay_unknown => '???';

  @override
  String get provinceOverlay_clickTileForDetails =>
      'Click a tile to see details.';

  @override
  String get provinceOverlay_tileCoordinatesUnknown => 'Coordinates: ???';

  @override
  String get provinceOverlay_tileTerrainUnknown => 'Terrain: ???';

  @override
  String get provinceOverlay_tileResourceUnknown => 'Resource: ???';

  @override
  String get provinceOverlay_tileProspectedUnknown => 'Prospected: ???';

  @override
  String get provinceOverlay_tileImprovementUnknown => 'Improvement: ???';

  @override
  String get provinceOverlay_tileRoadUnknown => 'Road / railroad: ???';

  @override
  String get provinceOverlay_tileCivilianUnitsUnknown =>
      'Civilian units (province): ???';

  @override
  String provinceOverlay_tileCoordinates(int x, int y) {
    return 'Coordinates: ($x, $y)';
  }

  @override
  String provinceOverlay_tileTerrain(String terrain) {
    return 'Terrain: $terrain';
  }

  @override
  String provinceOverlay_tileTownOf(String provinceName) {
    return 'The town of $provinceName';
  }

  @override
  String provinceOverlay_tileCapitalOf(
    String provinceName,
    String factionName,
  ) {
    return '$provinceName, the capital of $factionName';
  }

  @override
  String get provinceOverlay_tileResourcePrefix => 'Resource: ';

  @override
  String provinceOverlay_tileProspected(String value) {
    return 'Prospected: $value';
  }

  @override
  String get provinceOverlay_tileProspectedYes => 'yes';

  @override
  String get provinceOverlay_tileProspectedNo => 'no';

  @override
  String get provinceOverlay_tileProspectWithExplorerTooltip =>
      'Prospect with explorer';

  @override
  String get provinceOverlay_tileExploreWithExplorerTooltip =>
      'Explore with explorer';

  @override
  String provinceOverlay_tileExplorePayoffGist(int turns) {
    final duration = turns == 1 ? '1 turn' : '$turns turns';
    return 'After this work: this whole province becomes fully visible · Takes $duration';
  }

  @override
  String get provinceOverlay_tileConsulateRequiredForExploreTooltip =>
      'Establish a consulate before exploring or prospecting';

  @override
  String get provinceOverlay_tileConsulateRequiredForExploreNarrowTooltip =>
      'Establish a consulate before exploring or prospecting. '
      'Use Establish Consulate on Political.';

  @override
  String get provinceOverlay_tileBuildImprovementTooltip => 'Build improvement';

  @override
  String provinceOverlay_tileBuildImprovementTooltipWithCost(String costs) {
    return 'Build improvement ($costs)';
  }

  @override
  String provinceOverlay_tileBuildImprovementYieldRaise(
    int from,
    int to,
    String good,
  ) {
    return 'After this work: $from → $to $good if still linked';
  }

  @override
  String provinceOverlay_tileBuildImprovementYieldRoadLimit(
    int n,
    String good,
  ) {
    return 'After this work: still $n $good — the road is the limit';
  }

  @override
  String provinceOverlay_tileBuildImprovementYieldTownLimit(
    int n,
    String good,
  ) {
    return 'After this work: still $n $good — town development is the limit';
  }

  @override
  String get provinceOverlay_tileBuildImprovementYieldDisconnected =>
      'After this work: still none — not bound to the capital';

  @override
  String get provinceOverlay_tileBuildImprovementDisabledNoBuilderTooltip =>
      'No idle Builders';

  @override
  String provinceOverlay_tileBuildImprovementDisabledMaterialsTooltip(
    String reason,
  ) {
    return reason;
  }

  @override
  String get workOrderAfford_canAfford => 'Can afford';

  @override
  String workOrderAfford_shortMaterial(String commodity, int quantity) {
    return 'Short: $commodity ×$quantity';
  }

  @override
  String workOrderAfford_shortTreasury(int amount) {
    return 'Short: treasury ×$amount';
  }

  @override
  String get provinceOverlay_tileBuildRoadTooltip => 'Build road';

  @override
  String provinceOverlay_tileBuildRoadTooltipWithCost(String costs) {
    return 'Build road ($costs)';
  }

  @override
  String get provinceOverlay_tileBuildRoadDisabledNoEngineerTooltip =>
      'No Engineer available to build road';

  @override
  String get provinceOverlay_tileBuildRoadDisabledTooltip =>
      'No Engineer can assign road work here this turn';

  @override
  String provinceOverlay_tileBuildRoadDisabledMaterialsTooltip(String reason) {
    return reason;
  }

  @override
  String provinceOverlay_militaryFortStatus(String status) {
    return 'Fort: $status';
  }

  @override
  String get provinceOverlay_tileBuildFortTooltip => 'Build fort';

  @override
  String provinceOverlay_tileBuildFortTooltipWithCost(String costs) {
    return 'Build fort ($costs)';
  }

  @override
  String get provinceOverlay_tileBuildFortDisabledNoEngineerTooltip =>
      'No Engineer available to build fort';

  @override
  String get provinceOverlay_tileBuildFortDisabledTooltip =>
      'No Engineer can assign fort work here this turn';

  @override
  String provinceOverlay_tileBuildFortDisabledMaterialsTooltip(String reason) {
    return reason;
  }

  @override
  String provinceOverlay_tileBuildFortPayoffGist(
    String fromLabel,
    String toLabel,
    int turns,
  ) {
    final duration = turns == 1 ? '1 turn' : '$turns turns';
    return 'After this work: $fromLabel → $toLabel · Takes $duration';
  }

  @override
  String get provinceOverlay_tilePurchaseLandTooltip => 'Purchase land';

  @override
  String provinceOverlay_tilePurchaseLandTooltipWithCost(int amount) {
    return 'Purchase land — £$amount';
  }

  @override
  String get provinceOverlay_tilePurchaseLandDisabledNoMerchantTooltip =>
      'No idle Merchants';

  @override
  String get provinceOverlay_tilePurchaseLandDisabledEmbassyTooltip =>
      'Embassy required with this Minor or Tribe';

  @override
  String provinceOverlay_tilePurchaseLandDisabledTreasuryTooltip(int amount) {
    return 'Short: treasury ×$amount';
  }

  @override
  String provinceOverlay_tilePurchaseLandPayoffTradeable(
    String good,
    String court,
  ) {
    return '$good still sells as $court’s. After this work you get first bid '
        'on that sale, and gold when other courts buy it. The land stays theirs.';
  }

  @override
  String provinceOverlay_tilePurchaseLandPayoffRiches(
    String good,
    String court,
  ) {
    return '$good from this tile will go to your treasury after this work. '
        'The land stays $court’s.';
  }

  @override
  String provinceOverlay_tileImprovement(String value) {
    return 'Improvement: $value';
  }

  @override
  String get provinceOverlay_tileRoadNone => 'Road / railroad: -';

  @override
  String get provinceOverlay_tileCapitalLinkConnected =>
      'Capital link: Connected';

  @override
  String provinceOverlay_tileCapitalLinkConnectedWithPath(int level) {
    return 'Capital link: Connected (path transport level $level)';
  }

  @override
  String get provinceOverlay_tileCapitalLinkNotConnected =>
      'Capital link: Not connected — will not extract';

  @override
  String provinceOverlay_tileExtractionFromTile(int effective, int full) {
    return 'Extraction from this tile: $effective of $full';
  }

  @override
  String provinceOverlay_tileRoadTransportLevel(int level) {
    return 'Road / railroad: transport level $level';
  }

  @override
  String get provinceOverlay_tileRoadLabelNone => 'none';

  @override
  String get provinceOverlay_tileRoadLabelPrimitiveRoad => 'primitive road';

  @override
  String get provinceOverlay_tileRoadLabelImprovedRoad => 'improved road';

  @override
  String get provinceOverlay_tileRoadLabelPortOrRailroad => 'port or railroad';

  @override
  String get provinceOverlay_tileRoadLabelNonStandard =>
      'non-standard transport level';

  @override
  String get provinceOverlay_tileRoadRailGloss =>
      'Basic land link for connectivity and yield caps. '
      'Railroads are transport level 4.';

  @override
  String get provinceOverlay_improvementGeneric => 'Improvement';

  @override
  String get provinceOverlay_improvementFarm => 'Farm';

  @override
  String get provinceOverlay_improvementRanch => 'Ranch';

  @override
  String get provinceOverlay_improvementPasture => 'Pasture';

  @override
  String get provinceOverlay_improvementLumberCamp => 'Lumber camp';

  @override
  String get provinceOverlay_improvementPlantation => 'Plantation';

  @override
  String get provinceOverlay_improvementFurPost => 'Fur post';

  @override
  String get provinceOverlay_improvementMine => 'Mine';

  @override
  String provinceOverlay_tileCivilianUnits(int count) {
    return 'Civilian units (province): $count';
  }

  @override
  String provinceOverlay_seaZone(String name) {
    return 'Sea zone: $name';
  }

  @override
  String provinceOverlay_name(String name) {
    return 'Name: $name';
  }

  @override
  String provinceOverlay_owner(String owner) {
    return 'Owner: $owner';
  }

  @override
  String get provinceOverlay_ownerUnclaimed => 'Unclaimed';

  @override
  String provinceOverlay_region(String region) {
    return 'Region: $region';
  }

  @override
  String get provinceOverlay_capitalYes => 'Capital: Yes';

  @override
  String get provinceOverlay_capitalNo => 'Capital: No';

  @override
  String provinceOverlay_townDevelopment(int level) {
    return 'Town development: $level';
  }

  @override
  String provinceOverlay_townDevelopmentOfMax(int level, int max) {
    return 'Town development: $level of $max';
  }

  @override
  String get provinceOverlay_townDevelopmentGistMax =>
      'Fully developed; manufacturing bonus at maximum.';

  @override
  String get provinceOverlay_townDevelopmentGistBonusActiveNextAt4 =>
      'Town manufacturing bonus active; next bonus at level 4.';

  @override
  String get provinceOverlay_townDevelopmentGistNextAt4 =>
      'Next manufacturing bonus at level 4.';

  @override
  String get provinceOverlay_townDevelopmentGistNextAt2 =>
      'Next manufacturing bonus at level 2.';

  @override
  String get provinceOverlay_upgradeTownAction => 'Upgrade town';

  @override
  String get provinceOverlay_establishConsulateAction => 'Establish Consulate';

  @override
  String get provinceOverlay_cancelEstablishConsulateAction => 'Cancel';
}
