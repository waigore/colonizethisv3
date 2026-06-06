/// YAML rules shared by [check_disallowed_ast_patterns_test] and related suites.
const disallowedAstPatternsTestYaml = r'''
rules:
  - id: cascade_void_clear
    message: 'no cascade clear'
    match:
      kind: cascaded_method_invocation
      method_names:
        - clear
  - id: stream_where_is_map_as
    message: 'use whereType'
    match:
      kind: stream_where_is_map_as
  - id: avoid_print_suppression
    message: 'do not suppress avoid_print'
    match:
      kind: comment_substring
      contains: 'ignore: avoid_print'
  - id: strict_raw_types
    message: 'no raw generic core types'
    match:
      kind: raw_named_type
      type_names:
        - List
        - Map
        - Set
        - Iterable
        - Future
        - Stream
  - id: widget_build_method_too_long
    message: 'widget build body too long'
    match:
      kind: method_body_line_span
      function_name: build
      max_body_line_span: 3
      require_widget_class_extends: true
  - id: sea_zone_local_id_extraction
    message: 'do not strip sea-zone ids to local'
    match:
      kind: sea_zone_local_id_extraction
  - id: sea_zone_bucket_lookup_without_canonical_key
    message: 'sea-zone bucket lookup requires canonical key'
    match:
      kind: sea_zone_bucket_lookup_without_canonical_key
  - id: province_lookup_unprefixed_literal
    message: 'prefixed province id literals required for lookup'
    match:
      kind: unprefixed_province_id_string_literal_argument
      method_names:
        - getProvince
        - tryGetProvince
        - resolveToFullProvinceId
      argument_index: 1
  - id: province_world_state_lookup_unprefixed_literal
    message: 'prefixed province id literals required for WorldState lookup'
    match:
      kind: unprefixed_province_id_string_literal_argument
      method_names:
        - tryGetProvince
        - getProvince
        - resolveToFullProvinceId
      argument_index: 0
  - id: province_local_id_from_unprefixed_literal
    message: 'prefixed province id literals required for localIdFrom'
    match:
      kind: unprefixed_province_id_string_literal_argument
      method_names:
        - localIdFrom
      argument_index: 0
  - id: province_local_segment_boundary_only
    message: 'localSegmentFromStoredGameState is boundary-only'
    match:
      kind: province_local_segment_boundary_only
  - id: debug_console_logic_contract_boundary
    message: 'debug console must use logic contract imports only'
    match:
      kind: scoped_package_import_contract
      scoped_relative_path_prefixes:
        - packages/colonizethis_debug_console/lib/
      package_name: colonizethis_logic
      allowed_imports:
        - package:colonizethis_logic/debug_console_api.dart
  - id: logic_lib_list_queue_remove_at_zero
    message: >-
      Do not use a List named queue as a FIFO frontier (queue.removeAt(0)).
    match:
      kind: simple_receiver_remove_at_zero
      receiver_identifier: queue
      relative_path_prefix: packages/colonizethis_logic/lib/src/
  - id: prohibited_linear_province_lookup
    message: >-
      Do not chain .provinces.where(...).firstOrNull under
      packages/colonizethis_logic/lib/src/.
    match:
      kind: linear_collection_where_first_or_null
      collection_names:
        - provinces
      relative_path_prefix: packages/colonizethis_logic/lib/src/
  - id: prohibited_linear_units_armies_fleets_lookup
    message: >-
      Do not chain .units/.armies/.fleets.where(...).firstOrNull under
      packages/colonizethis_logic/lib/src/.
    match:
      kind: linear_collection_where_first_or_null
      collection_names:
        - units
        - armies
        - fleets
      relative_path_prefix: packages/colonizethis_logic/lib/src/
  - id: redundant_where_to_list_where_chain
    message: >-
      Do not chain .where(...).toList().where(...).
    match:
      kind: redundant_where_to_list_where_chain
  - id: nested_world_state_copywith
    message: >-
      Do not chain Game.copyWith(worldState: ...copyWith(...copyWith(...)))
      across three or more nesting levels in
      packages/colonizethis_logic/lib/. Use updateWorldState/updateTurnState.
    match:
      kind: nested_world_state_copywith
      relative_path_prefix: packages/colonizethis_logic/lib/
      outer_argument_name: worldState
  - id: ai_full_recipe_catalog_scan
    message: >-
      Do not scan ProductionRecipesCatalog.all under
      packages/colonizethis_ai/lib/. Use producing(commodityId) or byId index.
    match:
      kind: static_member_access
      type_name: ProductionRecipesCatalog
      member_name: all
      relative_path_prefix: packages/colonizethis_ai/lib/
''';
