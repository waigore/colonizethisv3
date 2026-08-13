import 'package:colonizethis_data/colonizethis_data.dart';

/// Check if a terrain type uses L2+ standalone tile rendering (features).
/// L0: Sea (Wang). L1: Plains/Desert (Wang). L2+: Features (standalone).
bool regionMapComponentIsFeatureTerrain(TerrainType terrain) {
  return isForestTerrain(terrain) ||
      terrain == TerrainType.hills ||
      terrain == TerrainType.mountain ||
      terrain == TerrainType.swamp;
}
