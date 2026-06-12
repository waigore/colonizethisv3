/// `parseTileKeyCoordinates` now lives in `colonizethis_models` (Refs #3427).
///
/// Re-exported here so existing `colonizethis_world` consumers — both the
/// barrel and internal `src/world/tile_key_coordinates.dart` imports — keep
/// resolving the symbol from this path unchanged.
export 'package:colonizethis_models/colonizethis_models.dart'
    show parseTileKeyCoordinates;
