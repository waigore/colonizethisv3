/// App-wide configuration constants for root-relative Flutter asset keys and
/// path prefixes. Path-building helpers (e.g. [terrainTileAssetPath]) live in
/// [app_assets.dart], which re-exports this library.
library;

/// Root-relative prefix for 32px toolbar / UI icon PNGs in the Flutter asset
/// bundle (see pubspec `assets:`).
const String kAppIconAssetPrefix = 'assets/icons/32/';

/// Root-relative prefix for 64px map / cache icon PNGs.
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
const String kDialogueTribeFirstContactAsset =
    'assets/dialogue/tribe_first_contact.yarn';

/// Map terrain config asset loaded at app startup.
const String kMapTerrainTilesetsAsset = 'assets/data/map_terrain_tilesets.json';

/// Root-relative prefix for blessed GA AI profile JSON assets.
const String kBlessedAiProfilesAssetPrefix = 'assets/profiles/';

/// Blessed AI profile manifest asset loaded at app startup.
const String kBlessedAiProfilesManifestAsset =
    '${kBlessedAiProfilesAssetPrefix}manifest.json';
