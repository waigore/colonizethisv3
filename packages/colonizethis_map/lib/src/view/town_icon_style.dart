import 'package:colonizethis_data/colonizethis_data.dart' show kNewWorldRegionId;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Town map icon style ids matching asset suffix (`euro`, `colonial`, `tribal`).
const String kTownIconStyleEuro = 'euro';
const String kTownIconStyleColonial = 'colonial';
const String kTownIconStyleTribal = 'tribal';

/// Cache / asset id for a style + level pair, e.g. `town_euro_3`.
String townIconIdFor({required String style, required int level}) {
  final clamped = normalizeTownDevelopmentLevel(level);
  return 'town_${style}_$clamped';
}

/// Deterministic style resolution per SPEC/ui/town-port-icons.md (Refs #3870).
String townIconStyleForProvince({
  required String regionId,
  required String? ownerId,
  required Game game,
}) {
  if (ownerId != null && game.tribes.any((t) => t.id == ownerId)) {
    return kTownIconStyleTribal;
  }
  if (regionId == kNewWorldRegionId &&
      (ownerId == null || game.players.any((p) => p.id == ownerId))) {
    return kTownIconStyleColonial;
  }
  return kTownIconStyleEuro;
}
