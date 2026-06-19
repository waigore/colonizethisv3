/// World-state helpers: connectivity, movement, fog, naval, tracing (Refs #3290).
library colonizethis_world;

export 'src/event_bus/game_event_bus.dart';
export 'src/game_events.dart';
export 'src/game_player_lookup.dart';
export 'src/logic_validation_exception.dart';
export 'package:colonizethis_world/src/trace/turn_trace_contracts.dart';
export 'package:colonizethis_world/src/trace/turn_trace_file_exporter.dart';
export 'package:colonizethis_world/src/trace/turn_trace_runtime.dart';
export 'src/world_constants.dart';
export 'package:colonizethis_world/src/world/army_commands.dart';
export 'package:colonizethis_world/src/world/army_ids.dart';
export 'package:colonizethis_world/src/world/ai_control.dart';
export 'package:colonizethis_world/src/world/army_migration.dart';
export 'package:colonizethis_world/src/world/army_movement.dart';
export 'package:colonizethis_world/src/world/capital_reassignment_fatal.dart';
export 'package:colonizethis_world/src/world/capital_and_gp_fall.dart';
export 'package:colonizethis_world/src/world/civilian_tile_occupancy.dart';
export 'package:colonizethis_world/src/world/connectivity_resolver.dart';
export 'package:colonizethis_world/src/world/faction_membership.dart';
export 'package:colonizethis_world/src/world/game_world_mutations.dart';
export 'package:colonizethis_world/src/world/unit_lookup.dart';
export 'package:colonizethis_world/src/world/minor_military_parity.dart';
export 'package:colonizethis_world/src/world/movement.dart';
export 'package:colonizethis_world/src/world/naval.dart';
// `landTileKeysForProvinceBucket` is the single canonical definition in
// `province_lookup.dart` (Refs #3403 Phase 1); the former duplicate here was
// removed, so this barrel re-export no longer needs a `hide` carve-out.
export 'package:colonizethis_world/src/world/naval_coastal_visibility.dart';
export 'package:colonizethis_world/src/world/naval_fleet_commands.dart';
export 'package:colonizethis_world/src/world/naval_mission_orders.dart';
export 'package:colonizethis_world/src/world/fog_resolution.dart'
    show
        applyCoastalSeaZoneFullVisibility,
        applyCoastalSeaZoneFullVisibilityForProvinceTargets;
export 'package:colonizethis_world/src/world/player_state_pipeline.dart';
export 'package:colonizethis_world/src/world/player_view.dart';
export 'package:colonizethis_world/src/world/province_owner_cache.dart';
export 'package:colonizethis_world/src/world/province_ownership_transfer.dart';
export 'package:colonizethis_world/src/world/province_lookup.dart';
export 'package:colonizethis_world/src/world/province_traversal.dart';
export 'package:colonizethis_world/src/world/province_visibility_index.dart';
export 'package:colonizethis_world/src/world/sea_zone_identity.dart';
export 'package:colonizethis_world/src/world/ship_instance_allocate.dart';
export 'package:colonizethis_world/src/world/tile_control.dart';
// `parseTileKeyCoordinates` now lives in `colonizethis_models` (Refs #3427) and
// is re-exported by `tile_key_coordinates.dart`. Because the canonical
// declaration is the single `colonizethis_models` one, the `colonizethis_world`
// and `colonizethis_orders` barrels re-export the same element, so the combined
// `colonizethis_logic` barrel no longer needs the prior `hide` workaround.
export 'package:colonizethis_world/src/world/tile_key_coordinates.dart';
// `enemiesOf` promoted to the public barrel (Refs #3427) so consumers such as
// `colonizethis_economy` (sea transport interception) import it through a
// barrel instead of a deep `src/` path. Only `enemiesOf` is surfaced to keep
// the rest of `diplomatic_relation_lookup.dart` internal.
export 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart'
    show enemiesOf;
export 'package:colonizethis_world/src/world/topology_helpers.dart';
// `reachableNonOwnedProvinceIdsViaSeas` / `reachableNonOwnedProvinceDistancesViaSeas`
// promoted to the public barrel (Refs #3543) so consumers such as
// `colonizethis_orders` and `colonizethis_diplomacy` import them through the
// barrel instead of a deep `src/` path. The `ai_api.dart` narrow contract
// re-exports these symbols through this barrel rather than a deep src export.
export 'package:colonizethis_world/src/world/sea_reachable_provinces.dart';
