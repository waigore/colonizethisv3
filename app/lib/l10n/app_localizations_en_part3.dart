part of 'app_localizations_en.dart';

mixin _AppLocalizationsEnStrings3 on AppLocalizations {
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
  String get production_available => 'Available';

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
  String technologyPanel_pickSubtitle(String era, String category, int cost) {
    return 'Era $era - $category - $cost RP';
  }

  @override
  String get technologyPanel_slotCancelled => 'Research slot cancelled';

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
  String get provinceOverlay_tileResourcePrefix => 'Resource: ';

  @override
  String provinceOverlay_tileProspected(String value) {
    return 'Prospected: $value';
  }

  @override
  String get provinceOverlay_tileProspectWithExplorerTooltip =>
      'Prospect with explorer';

  @override
  String get provinceOverlay_tileExploreWithExplorerTooltip =>
      'Explore with explorer';

  @override
  String get provinceOverlay_tileBuildImprovementTooltip => 'Build improvement';

  @override
  String provinceOverlay_tileImprovement(String value) {
    return 'Improvement: $value';
  }

  @override
  String get provinceOverlay_tileRoadNone => 'Road / railroad: -';

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
  String provinceOverlay_indentedCount(String label, int count) {
    return '  $label: $count';
  }

  @override
  String provinceOverlay_unitTarget(String type, String id, String target) {
    return '$type ($id): $target';
  }

  @override
  String provinceOverlay_foreignUnitStatus(
    String owner,
    String type,
    String id,
    String status,
  ) {
    return '$owner — $type ($id): $status';
  }

  @override
  String provinceOverlay_fleetSummary(
    String owner,
    String fleetLabel,
    String shipParts,
  ) {
    return '$owner — $fleetLabel: $shipParts';
  }

  @override
  String get provinceOverlay_sectionPolitical => 'Political';

  @override
  String get provinceOverlay_sectionTile => 'Tile';

  @override
  String get provinceOverlay_sectionEconomic => 'Economic';

  @override
  String get provinceOverlay_sectionMilitary => 'Military';

  @override
  String get provinceOverlay_sectionCivilian => 'Civilian';

  @override
  String get provinceOverlay_sectionNaval => 'Naval';

  @override
  String get gameSetup_title => 'Game Setup';

  @override
  String get gameSetup_starting => 'Starting…';

  @override
  String get gameSetup_startGame => 'Start Game';

  @override
  String get gameSetup_back => 'Back';

  @override
  String get gameSetup_player1You => 'Player 1 (You)';

  @override
  String gameSetup_playerAiSlot(int n) {
    return 'Player $n (AI)';
  }

  @override
  String get gameSetup_selectNation => 'Select nation';

  @override
  String get gameSetup_selectLeader => 'Select leader';

  @override
  String get mapCorner_tooltipBaseLayer =>
      'Base layer: terrain / +resources / +improvements';

  @override
  String get mapCorner_tooltipCenterCapital => 'Center on capital';

  @override
  String get mapCorner_tooltipMapDisplayOptions => 'Map display options';

  @override
  String mapControls_cargoHold(String used, String capacity) {
    return '$used/$capacity';
  }

  @override
  String common_percent(int value) {
    return '$value%';
  }

  @override
  String get regionMinimap_mapZoom => 'Map zoom';

  @override
  String regionMinimap_zoomSemanticsValue(int pct) {
    return '$pct percent';
  }

  @override
  String province_economic_resourceRow(
    String terrain,
    String resourceId,
    String detail,
  ) {
    return '$terrain/$resourceId $detail';
  }

  @override
  String get diplomacy_detail_historyTitle => 'Diplomatic history';

  @override
  String get diplomacy_detail_noEvents =>
      'No recorded events with this faction.';

  @override
  String diplomacy_detail_yearTurn(int year, int turn) {
    return '$year (Turn $turn)';
  }

  @override
  String get diplomacy_detail_dossierTitle => 'Dossier';

  @override
  String get diplomacy_detail_currentRelation => 'Current relation';

  @override
  String get diplomacy_detail_noDossier => 'No dossier evidence yet.';

  @override
  String diplomacy_detail_turnEvidence(int turn) {
    return 'Turn $turn:';
  }

  @override
  String get diplomacy_panel_noFactions => 'No other factions discovered yet.';

  @override
  String diplomacy_panel_powerScore(int score) {
    return 'Power: $score';
  }

  @override
  String diplomacy_panel_outgoingSubsidy(int amount, String target) {
    return 'Outgoing subsidy: £$amount/turn to $target';
  }

  @override
  String diplomacy_panel_pendingGrant(int amount) {
    return 'Pending grant aid: £$amount (resolves end of turn)';
  }

  @override
  String diplomacy_panel_pendingSubsidy(int amount) {
    return 'Pending subsidy: £$amount/turn (resolves end of turn)';
  }

  @override
  String production_commodityStock(String name, int qty, String change) {
    return '$name: $qty$change';
  }

  @override
  String production_effectiveLabour(int n) {
    return 'Effective labour: $n';
  }

  @override
  String production_recipeAffordance(int max, String limiting) {
    return '$max · $limiting';
  }

  @override
  String production_totalLabour(int required, int effective) {
    return 'Total labour: $required / $effective';
  }

  @override
  String get production_labourInsufficient =>
      'Insufficient labour — production will be capped next turn';

  @override
  String production_workerCount(String name, int count) {
    return '$name: $count';
  }

  @override
  String naval_units_shipTypeCount(String typeName, int count) {
    return '$typeName: $count';
  }

}
