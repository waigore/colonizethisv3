part of 'app_localizations_en.dart';

mixin _AppLocalizationsEnStrings2 on AppLocalizations {
  @override
  String quickBattle_battleResult(String winnerText) {
    return 'Battle Result: $winnerText';
  }

  @override
  String get quickBattle_provinceCaptured => 'Province captured.';

  @override
  String quickBattle_casualties(String name, int count) {
    return '$name casualties: $count';
  }

  @override
  String get quickBattle_ok => 'OK';

  @override
  String quickBattle_round(int round, int maxRounds) {
    return 'Quick Battle — Round $round / $maxRounds';
  }

  @override
  String get quickBattle_resolveAuto => 'Resolve (Auto)';

  @override
  String get quickBattle_attackerDefaultName => 'Attacker';

  @override
  String get quickBattle_defenderDefaultName => 'Defender';

  @override
  String game_intro_loadError(String error) {
    return 'Could not load intro dialogue: $error';
  }

  @override
  String game_overture_loadError(String error) {
    return 'Could not load overture dialogue: $error';
  }

  @override
  String get game_overture_title => 'Diplomatic overtures';

  @override
  String get game_overture_intro => 'Accept or reject each offer.';

  @override
  String game_overture_offerLine(String offerer, String stage) {
    return '$offerer: $stage';
  }

  @override
  String get game_overture_accept => 'Accept';

  @override
  String get game_overture_reject => 'Reject';

  @override
  String get victory_military => 'Military victory';

  @override
  String victory_winnerOnTurn(String winner, int turn) {
    return '$winner wins on turn $turn.';
  }

  @override
  String get victory_returnToMainMenu => 'Return to main menu';

  @override
  String get victory_viewFinalState => 'View final state';

  @override
  String get moveArmy_groupYourProvinces => 'Your provinces';

  @override
  String get moveArmy_groupUnowned => 'Unowned';

  @override
  String get moveArmy_invadeProvinceTitle => 'Invade province?';

  @override
  String moveArmy_invadeProvinceBody(String ownerLabel) {
    return 'Moving into $ownerLabel territory will declare war this turn and then move the army. Continue?';
  }

  @override
  String get moveArmy_declareWarAndMove => 'Declare war and move';

  @override
  String moveArmy_title(String armyId) {
    return 'Move army $armyId';
  }

  @override
  String get moveArmy_noValidDestinations => 'No valid destinations.';

  @override
  String get moveArmy_destinationProvince => 'Destination province';

  @override
  String moveFleet_title(String fleetLabel) {
    return 'Move fleet — $fleetLabel';
  }

  @override
  String moveFleet_titleWithDestinations(String fleetLabel, int count) {
    return 'Move fleet — $fleetLabel ($count destinations)';
  }

  @override
  String get moveFleet_noAdjacentSeaZones =>
      'No adjacent sea zones (check map topology).';

  @override
  String get moveFleet_seaZonesSection => 'Sea zones';

  @override
  String get moveFleet_provincesDockSection => 'Provinces (dock)';

  @override
  String get moveFleet_locateOnMap => 'Locate on map';

  @override
  String get moveFleet_warpLink => 'links';

  @override
  String moveFleet_warpLinkToRegion(String region) {
    return 'links to $region';
  }

  @override
  String get military_units_title => 'Military Units';

  @override
  String get military_units_deselectAllArmies => 'Deselect all armies';

  @override
  String get military_units_selectAllArmies => 'Select all armies';

  @override
  String get military_units_empty => 'No military units';

  @override
  String get military_units_homeArmy => 'Home Army';

  @override
  String military_units_army(String armyId) {
    return 'Army $armyId';
  }

  @override
  String military_units_armySubtitle(int regiments, String location) {
    return '$regiments regiments · $location';
  }

  @override
  String military_units_armySubtitleWithDraft(
    int regiments,
    String location,
    String draftLine,
  ) {
    return '$regiments regiments · $location\n$draftLine';
  }

  @override
  String get military_units_noRegimentsAssigned => 'No regiments assigned';

  @override
  String military_units_typeCount(String typeName, int count) {
    return '$typeName: $count';
  }

  @override
  String military_units_regimentSubtitle(String medals, String status) {
    return 'Medals: $medals · Status: $status';
  }

  @override
  String military_units_status(String status) {
    return 'Status: $status';
  }

  @override
  String get naval_units_title => 'Naval Units';

  @override
  String get naval_units_title_tile => 'Naval Units (Tile)';

  @override
  String get naval_units_deselectAllFleets => 'Deselect all fleets';

  @override
  String get naval_units_selectAllFleets => 'Select all fleets';

  @override
  String get naval_units_empty => 'No naval units';

  @override
  String naval_units_totalShips(int count) {
    return 'Total ships: $count';
  }

  @override
  String naval_units_strength(String value) {
    return 'Strength: $value';
  }

  @override
  String naval_units_warships(int count) {
    return '$count warships';
  }

  @override
  String naval_units_merchants(int count) {
    return '$count merchants';
  }

  @override
  String get naval_units_locateFleet => 'Locate fleet';

  @override
  String naval_units_mission(String mission) {
    return 'Mission: $mission';
  }

  @override
  String get naval_units_noShipsInFleet => 'No ships in this fleet';

  @override
  String naval_units_cargoCapacity(int capacity) {
    return 'Cargo capacity: $capacity';
  }

  @override
  String naval_units_cargoCapacityIfAssigned(int capacity) {
    return 'Cargo capacity (if assigned): $capacity';
  }

  @override
  String get diplomacy_setSubsidy => 'Set subsidy';

  @override
  String get diplomacy_grantAid => 'Grant aid';

  @override
  String diplomacy_treasuryStep(int treasury, int step) {
    return 'Treasury: £$treasury. Step: £$step.';
  }

  @override
  String diplomacy_currencyAmount(int amount) {
    return '£$amount';
  }

  @override
  String diplomacy_treasuryBelowMinimum(int step) {
    return 'Treasury is below the minimum valid amount (£$step).';
  }

  @override
  String get trainCivilians_title => 'Train Civilians';

  @override
  String get trainMilitary_title => 'Train Military';

  @override
  String get trainUnits_noCapital => 'No capital set — cannot train units';

  @override
  String trainUnits_treasury(String value) {
    return 'Treasury: $value';
  }

  @override
  String trainUnits_paper(int value) {
    return 'Paper: $value';
  }

  @override
  String trainUnits_peasants(int value) {
    return 'Peasants: $value';
  }

  @override
  String get civilian_units_title => 'Civilian Units';

  @override
  String get civilian_units_title_tile => 'Civilian Units (Tile)';

  @override
  String get civilian_units_tile => 'Tile';

  @override
  String get civilian_units_empty => 'No civilian units';

  @override
  String civilian_units_status(String status) {
    return 'Status: $status';
  }

  @override
  String civilian_units_location(String location) {
    return 'Location: $location';
  }

  @override
  String civilian_units_assignedTo(String target) {
    return 'Assigned to: $target';
  }

  @override
  String get civilian_units_assign => 'Assign';

  @override
  String civilian_units_turns(int count) {
    if (count == 1) {
      return '$count turn';
    }
    return '$count turns';
  }

  @override
  String civilian_units_turnProgress(String remaining, String total) {
    return '$remaining/$total turns';
  }

  @override
  String get naval_transferToHome_dialogTitle => 'Transfer Ships to Home Fleet';

  @override
  String naval_transferToHome_sourceTitle(String id) {
    return 'Fleet $id';
  }

  @override
  String get naval_transferToHome_confirm => 'Confirm Transfer';

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
}
