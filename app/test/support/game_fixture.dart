// Loader for the committed seed-42 game fixture (Refs #3656).
//
// Re-exports the lib implementation so tests keep `import 'support/game_fixture.dart'`.

export 'package:colonizethis_app/test_support/seed42_fixture_loader.dart'
    show
        kSeed42GameFixtureRepoPath,
        loadSeed42Game,
        readSeed42GameFixtureJson,
        seed42GameFixtureFile;
