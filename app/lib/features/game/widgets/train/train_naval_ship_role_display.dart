import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

/// Pure display helpers for ship role and capability gist on Train Naval rows.
/// SPEC/ui/train-naval-dialog.md; GDD: SPEC/game/ships-and-naval.md,
/// SPEC/game/tech-tree-naval.md § Notes.
class TrainNavalShipRoleDisplay {
  TrainNavalShipRoleDisplay._();

  static bool isMerchant(String shipTypeId) =>
      NavalStatsCatalog.get(shipTypeId).cargoHold > 0;

  static String roleLabel(AppLocalizations l10n, String shipTypeId) =>
      isMerchant(shipTypeId)
      ? l10n.naval_units_compositionRoleMerchant
      : l10n.naval_units_compositionRoleWarship;

  /// Merchant: `+N cargo holds`. Warship: authored combat-role gist only.
  static String capabilityLine(AppLocalizations l10n, String shipTypeId) {
    final cargoHold = NavalStatsCatalog.get(shipTypeId).cargoHold;
    if (cargoHold > 0) {
      return l10n.trainNaval_merchantCargoHolds(cargoHold);
    }
    return warshipCombatRoleGist(l10n, shipTypeId);
  }

  static String warshipCombatRoleGist(AppLocalizations l10n, String shipTypeId) {
    switch (shipTypeId) {
      case 'sloop':
      case 'frigate':
      case 'raider':
        return l10n.trainNaval_warshipRoleFastInterceptor;
      case 'ship_of_the_line':
      case 'ironclad':
        return l10n.trainNaval_warshipRoleBattleShip;
      default:
        return l10n.naval_units_compositionRoleWarship;
    }
  }
}
