// Deterministic JSON serialization for [InitGameMapViewData] and its parts.
//
// `mapViewData` lives on `InitGameResult`, not on `Game`, so `Game.toJson()` /
// `Game.fromJson()` cannot reconstruct what the map-view widget suites read
// (Refs #3656). These helpers let the map-dependent suites load a committed,
// pre-generated seed-42 fixture (see `app/test/support/fixtures/` and
// `seed42_fixture_loader.dart`) instead of
// paying the ~7-11s procedural map generation per test isolate.
//
// Serialization is deterministic: optional/null fields and default-valued flags
// are omitted so that `serialize(deserialize(json)) == json` holds as a plain
// string comparison, which the round-trip guard test relies on
// (`map_view_fixture_roundtrip_test.dart`).
//
// Library parts: `map_view_serialization_write.dart` (to-JSON helpers),
// `map_view_serialization_read.dart` (from-JSON helpers). Refs #3878.

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kTownDevelopmentLevelMin;

part 'map_view_serialization_write.dart';
part 'map_view_serialization_read.dart';

/// Current fixture schema version. Bump when the serialized shape changes so a
/// stale committed fixture fails fast in the round-trip guard.
const int kMapViewFixtureVersion = 1;
