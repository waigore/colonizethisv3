// Canonical paths for committed seed-42 fixtures (Refs #3656, #3847).
//
// Fixtures live under `app/test/support/fixtures/`; loaders resolve them from
// either the `app/` package directory or the repository root.

/// Repo-relative path to the committed seed-42 [Game] JSON fixture.
const String kSeed42GameFixtureRepoPath =
    'app/test/support/fixtures/seed42_game.json';

/// Repo-relative path to the committed seed-42 map-view JSON fixture.
const String kSeed42MapViewFixtureRepoPath =
    'app/test/support/fixtures/seed42_map_view.json';

/// Candidate paths for [kSeed42GameFixtureRepoPath].
const List<String> kSeed42GameFixtureCandidatePaths = <String>[
  'test/support/fixtures/seed42_game.json',
  kSeed42GameFixtureRepoPath,
];

/// Candidate paths for [kSeed42MapViewFixtureRepoPath].
const List<String> kSeed42MapViewFixtureCandidatePaths = <String>[
  'test/support/fixtures/seed42_map_view.json',
  kSeed42MapViewFixtureRepoPath,
];
