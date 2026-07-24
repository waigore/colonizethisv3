// Loader for the committed seed-42 game fixture (Refs #3656 / #4117 slice F).
//
// Re-exports the lib implementation so tests keep `import 'game_fixture.dart'`.

export 'package:colonizethis_app_fixtures/test_support/seed42_fixture_loader.dart'
    show
        kSeed42GameFixtureRepoPath,
        loadSeed42Game,
        readSeed42GameFixtureJson,
        seed42GameFixtureFile;
