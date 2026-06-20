import 'app_constants.dart';

export 'app_constants.dart';

/// Full path for a terrain tile PNG given its stem (no extension).
String terrainTileAssetPath(String assetStem) =>
    '$kTerrainTileAssetPrefix$assetStem.png';

/// Full asset path for a blessed AI profile JSON given its manifest name.
String blessedAiProfileAssetPath(String profileName) =>
    '$kBlessedAiProfilesAssetPrefix$profileName.json';
