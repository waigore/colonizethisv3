/// Display-only Build fort payoff gist. Refs #4668.
library;

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_invasion_intel_labels.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Localized one-line gist for the next fort siege posture and work duration.
String buildFortPayoffGistLine({
  required AppLocalizations l10n,
  required String fromLabel,
  required String toLabel,
  required int turns,
}) {
  return l10n.provinceOverlay_tileBuildFortPayoffGist(
    fromLabel,
    toLabel,
    turns,
  );
}

/// Resolves gist when Build fort is enabled for a human-owned town tile.
String? buildFortPayoffGistForTile({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required String tileKey,
  required bool enabled,
  bool canMutateViaUi = true,
}) {
  if (!enabled || !canMutateViaUi) return null;
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return null;
  final province = game.worldState.tryGetProvince(provinceId);
  if (province == null || province.ownerId != humanPlayerId) return null;
  final fortLevel = province.fortLevel;
  if (fortLevel >= 3) return null;
  final fromLabel = moveArmyFortLabelForLevel(l10n, fortLevel);
  final toLabel = moveArmyFortLabelForLevel(l10n, fortLevel + 1);
  final turns = totalTurnsForWork(kWorkTargetBuildFort, fortLevel: fortLevel);
  return buildFortPayoffGistLine(
    l10n: l10n,
    fromLabel: fromLabel,
    toLabel: toLabel,
    turns: turns,
  );
}
