/// Place, unit, army, fleet, and faction labels for staged-decree rows.
library;

import 'package:colonizethis_app/core/utils/faction_display_name.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

String stagedDecreeUnitTypeLabel(Game? game, String unitId, String fallback) {
  if (game == null) return fallback;
  return game.worldState.tryGetUnitById(unitId)?.type ?? fallback;
}

String stagedDecreeArmyLabel(Game? game, String armyId, AppLocalizations l10n) {
  if (game != null) {
    for (final army in game.worldState.armies) {
      if (army.id == armyId) {
        return army.isHomeArmy
            ? l10n.military_units_homeArmy
            : l10n.military_units_army(army.id);
      }
    }
  }
  return l10n.military_units_army(armyId);
}

String stagedDecreeFleetLabel(
  String fleetId,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  if (fleetId == homeFleetIdFor(humanPlayerId)) {
    return l10n.naval_homeFleetLabel;
  }
  return l10n.naval_fleetLabel(fleetId);
}

String stagedDecreeFactionLabel(Game? game, String factionId) {
  if (game == null) return factionId;
  return displayNameForFaction(game, factionId);
}

String stagedDecreeProvinceLabel(Game? game, String prefixedId) {
  if (game == null) return prefixedId;
  final name = game.worldState.tryGetProvince(prefixedId)?.displayName;
  if (name != null && name.isNotEmpty) return name;
  return prefixedId;
}

String stagedDecreePlaceFromTileKey(Game? game, String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 2) return tileKey;
  return stagedDecreeProvinceLabel(game, '${parts[0]}|${parts[1]}');
}

String stagedDecreeNavalMovePlace(Game? game, NavalMoveOrder order) {
  final port = order.destinationPortProvinceId;
  if (port != null && port.isNotEmpty) {
    return stagedDecreeProvinceLabel(game, port);
  }
  final sea = order.destinationSeaZoneId;
  if (sea == null || sea.isEmpty) return '';
  final named = game?.worldState.seaZoneDisplayNameById[sea];
  if (named != null && named.isNotEmpty) return named;
  return sea;
}

String stagedDecreeTierName(AppLocalizations l10n, WorkerTier tier) {
  return switch (tier) {
    WorkerTier.peasant => l10n.production_workers_peasants,
    WorkerTier.apprentice => l10n.production_workers_apprentices,
    WorkerTier.journeyman => l10n.production_workers_journeymen,
    WorkerTier.master => l10n.production_workers_masters,
  };
}

String stagedDecreeFundingLabel(
  AppLocalizations l10n,
  ResearchFundingLevel level,
) {
  return switch (level) {
    ResearchFundingLevel.none => l10n.technologyPanel_fundingNone,
    ResearchFundingLevel.low => l10n.technologyPanel_fundingLow,
    ResearchFundingLevel.medium => l10n.technologyPanel_fundingMedium,
    ResearchFundingLevel.high => l10n.technologyPanel_fundingHigh,
    ResearchFundingLevel.maximum => l10n.technologyPanel_fundingMaximum,
  };
}
