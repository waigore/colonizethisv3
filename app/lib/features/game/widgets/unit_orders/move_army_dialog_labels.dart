// Move army dialog label helpers. SPEC/ui/move-army-dialog.md.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

String moveArmyFactionGroupHeaderLabel(
  Game game,
  ArmyMovePickerDestination entry,
  AppLocalizations l10n,
) {
  if (entry.isPlayerOwned) return l10n.moveArmy_groupYourProvinces;
  if (entry.ownerFactionId == '__unowned__') return l10n.moveArmy_groupUnowned;
  final gp = game.playerById(entry.ownerFactionId);
  if (gp != null) return gp.displayName;
  for (final m in game.minorNations) {
    if (m.id == entry.ownerFactionId) {
      return m.displayName ?? m.id;
    }
  }
  for (final t in game.tribes) {
    if (t.id == entry.ownerFactionId) {
      return t.displayName ?? t.id;
    }
  }
  return entry.ownerFactionId;
}
