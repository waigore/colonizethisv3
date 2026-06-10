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
// `landTileKeysForProvinceBucket` is also defined in `province_lookup.dart`
// (already published); keep that as the public symbol and hide the duplicate
// here to avoid an ambiguous export (Refs #3393 Phase 1).
export 'package:colonizethis_world/src/world/naval_coastal_visibility.dart'
    hide landTileKeysForProvinceBucket;
export 'package:colonizethis_world/src/world/naval_fleet_commands.dart';
export 'package:colonizethis_world/src/world/naval_mission_orders.dart';
export 'package:colonizethis_world/src/world/fog_resolution.dart'
    show
        applyCoastalSeaZoneFullVisibility,
        applyCoastalSeaZoneFullVisibilityForProvinceTargets;
export 'package:colonizethis_world/src/world/player_state_pipeline.dart';
export 'package:colonizethis_world/src/world/player_view.dart';
export 'package:colonizethis_world/src/world/province_ownership_transfer.dart';
export 'package:colonizethis_world/src/world/province_lookup.dart';
export 'package:colonizethis_world/src/world/province_traversal.dart';
export 'package:colonizethis_world/src/world/province_visibility_index.dart';
export 'package:colonizethis_world/src/world/sea_zone_identity.dart';
export 'package:colonizethis_world/src/world/ship_instance_allocate.dart';
export 'package:colonizethis_world/src/world/tile_control.dart';
// `parseTileKeyCoordinates` is also published by the `colonizethis_orders`
// barrel (a thin forwarder to this canonical implementation); hide it here so
// the combined `colonizethis_logic` barrel keeps a single public source and
// avoids an ambiguous export (Refs #3393 Phase 1).
export 'package:colonizethis_world/src/world/tile_key_coordinates.dart'
    hide parseTileKeyCoordinates;
export 'package:colonizethis_world/src/world/topology_helpers.dart';
