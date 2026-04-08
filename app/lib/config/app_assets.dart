/// Root-relative prefix for UI icon PNGs in the Flutter asset bundle (see pubspec `assets:`).
const String kAppIconAssetPrefix = 'assets/icons/32/';
const String kAppIcon32AssetPrefix = 'assets/icons/32/';
const String kAppIcon64AssetPrefix = 'assets/icons/64/';

/// Root-relative prefix for terrain tile PNGs.
const String kTerrainTileAssetPrefix = 'assets/images/terrain/tile_';

/// Main menu pixel-art assets.
const String kMainMenuLogoAsset = 'assets/images/ui_main_menu_logo.png';
const String kMainMenuBackgroundAsset =
    'assets/images/ui_main_menu_background.png';

/// Dialogue script assets.
const String kDialogueGameIntroAsset = 'assets/dialogue/game_intro.yarn';
const String kDialogueInterventionAsset = 'assets/dialogue/intervention.yarn';
const String kDialogueOvertureAsset = 'assets/dialogue/overture.yarn';

/// Map terrain config asset loaded at app startup.
const String kMapTerrainTilesetsAsset = 'assets/data/map_terrain_tilesets.json';

String terrainTileAssetPath(String assetStem) =>
    '$kTerrainTileAssetPrefix$assetStem.png';
