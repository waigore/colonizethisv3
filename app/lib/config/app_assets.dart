import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';

import 'app_constants.dart';

export 'app_constants.dart';

/// Full path for a terrain tile PNG given its stem (no extension).
///
/// Uses [ActiveMapTheme.current] standalone prefix (default =
/// [kTerrainTileAssetPrefix]). SPEC/program/map-theme-catalog.md.
String terrainTileAssetPath(String assetStem) =>
    '${ActiveMapTheme.current.terrainStandaloneTilePrefix}$assetStem.png';

/// Full asset path for a blessed AI profile JSON given its manifest name.
String blessedAiProfileAssetPath(String profileName) =>
    '$kBlessedAiProfilesAssetPrefix$profileName.json';
