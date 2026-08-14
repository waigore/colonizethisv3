import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Pure display helper for civilian role gists on Train Civilians rows.
/// SPEC/ui/train-civilians-dialog.md; GDD: SPEC/game/civilian-units.md;
/// sibling pattern: [TrainNavalShipRoleDisplay] / [TrainMilitaryRegimentRoleDisplay].
class TrainCivilianRoleDisplay {
  TrainCivilianRoleDisplay._();

  /// One muted plain-language role gist under the type name (no raw work-target
  /// ids). Spy copy describes intel / counter-espionage work only — it must not
  /// imply an unassigned Spy is unused capacity (UXD-002 / Refs #4366).
  static String roleGist(AppLocalizations l10n, String civilianTypeId) {
    switch (civilianTypeId) {
      case kUnitTypeExplorer:
        return l10n.trainCivilians_roleGistExplorer;
      case kUnitTypeBuilder:
        return l10n.trainCivilians_roleGistBuilder;
      case kUnitTypeEngineer:
        return l10n.trainCivilians_roleGistEngineer;
      case kUnitTypeSpy:
        return l10n.trainCivilians_roleGistSpy;
      case kUnitTypeMerchant:
        return l10n.trainCivilians_roleGistMerchant;
      case kUnitTypeRailBuilder:
        return l10n.trainCivilians_roleGistRailBuilder;
      default:
        return '';
    }
  }
}
