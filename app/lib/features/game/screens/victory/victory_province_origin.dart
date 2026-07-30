import 'package:colonizethis_models/colonizethis_models.dart';

import 'victory_standings.dart';

/// Plain-language province origin/capture line for the Victory political minimap.
/// SPEC/ui/victory-panel.md § Political minimap inspect.
String victoryProvinceInspectLabel(Game game, Province province) {
  final originalId = province.originalOwnerId;
  final localName =
      province.displayName ?? ProvinceId.localIdFrom(province.id);
  if (originalId == null || originalId.isEmpty) {
    return '$localName — founding owner unknown for this province.';
  }
  final originalName = displayNameForVictoryFaction(game, originalId);
  final currentOwner = province.ownerId;
  if (currentOwner == originalId) {
    return '$localName — still held by its founding power, $originalName.';
  }
  final currentLabel = currentOwner == null || currentOwner.isEmpty
      ? 'unowned'
      : displayNameForVictoryFaction(game, currentOwner);
  return '$localName — captured from $originalName (now $currentLabel).';
}
