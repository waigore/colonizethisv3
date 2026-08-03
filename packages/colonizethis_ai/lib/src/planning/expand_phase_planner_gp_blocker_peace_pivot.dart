import '../perception/perception_snapshot.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

/// Resolved minor-on-frontier / stalled GP-blocker-focus pivot inputs shared by
/// the EXPAND stalled-expansion peace deciders, or `null` when neither pivot
/// applies (no invadable OW province owned by an OW minor **and** not in the
/// stalled GP-blocker-focus band).
({
  Map<String, String> provinceOwner,
  bool minorsOwnInvadable,
  bool gpBlockerFocus,
})?
resolveStalledMinorOrGpBlockerPivot({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
  );
  final gpBlockerFocus = isStalledOldWorldGpBlockerFocus(
    game: game,
    snapshot: snapshot,
  );
  if (!minorsOwnInvadable && !gpBlockerFocus) {
    return null;
  }
  return (
    provinceOwner: provinceOwner,
    minorsOwnInvadable: minorsOwnInvadable,
    gpBlockerFocus: gpBlockerFocus,
  );
}
