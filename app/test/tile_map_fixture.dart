// Loader for the committed seed-42 per-region tile-map fixture (Refs #3656 / #4117 slice F).
//
// Re-exports the lib implementation so tests keep `import 'support/tile_map_fixture.dart'`.

export 'package:colonizethis_app_fixtures/test_support/seed42_fixture_loader.dart'
    show kSeed42TileMapFixtureRepoPath;
export 'package:colonizethis_app_fixtures/test_support/seed42_tile_map_loader.dart'
    show
        kTileMapFixtureVersion,
        loadSeed42TileMapByRegion,
        readSeed42TileMapFixtureJson,
        seed42TileMapFixtureFile,
        seed42TileMapToJson;
