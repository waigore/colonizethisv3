// Loader for the committed seed-42 per-region tile-map fixture (Refs #3656).
//
// Re-exports the lib implementation so tests keep `import 'support/tile_map_fixture.dart'`.

export 'package:colonizethis_app/test_support/seed42_tile_map_loader.dart'
    show
        kSeed42TileMapFixtureRepoPath,
        kTileMapFixtureVersion,
        loadSeed42TileMapByRegion,
        readSeed42TileMapFixtureJson,
        seed42TileMapFixtureFile,
        seed42TileMapToJson;
