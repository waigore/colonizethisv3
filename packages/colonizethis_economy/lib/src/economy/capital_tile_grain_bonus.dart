import 'package:colonizethis_models/colonizethis_models.dart';

/// Capital-tile grain bonus amount for [player], or `null` when ineligible.
///
/// Eligibility: the player has a capital tile and
/// [Game.capitalTileGrainBonusPerTurn] is positive. Callers decide which
/// destination map receives the bonus (land totals, region projection, or
/// capital-province snapshot). Does not scan tiles.
int? capitalTileGrainBonusForPlayer({
  required Game game,
  required Player player,
}) {
  if (player.capitalTile == null) return null;
  final bonus = game.capitalTileGrainBonusPerTurn;
  if (bonus <= 0) return null;
  return bonus;
}
