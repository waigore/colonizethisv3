import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking gate for #3656: `app/test/**` files must not call the expensive
/// `getDebugInitGameResult()` debug map generator outside a documented
/// allowlist of suites that genuinely need generated map/topology data.
///
/// `getDebugInitGameResult()` runs the full procedural map generator
/// (`runInitGame(GameSetupConfig.defaultConfig)`, ~7-11s per call). Because
/// `flutter test` isolates each file, the cost is paid once per file. Panels
/// that only render from a `Game` should use the shared lightweight fixtures in
/// `app/test/support/panel_test_fixtures.dart` instead.
///
/// The allowlist below is the migration backlog: every `app/test/**` file that
/// still calls the helper. It must only ever **shrink** as families migrate to
/// lightweight or serialized fixtures; new entries require justification.
const Set<String> _kDebugInitAllowlist = <String>{
  'app/test/ct_e2e_turn_snapshot_refresh_test.dart',
  'app/test/ct_game_feature_screen_shell_test.dart',
  'app/test/ct_region_map_debug_init_test.dart',
  'app/test/ct_region_map_test_support.dart',
  'app/test/diplomacy_detail_screen_test.dart',
  'app/test/diplomacy_dialogs_test.dart',
  'app/test/diplomacy_panel_chrome_test.dart',
  'app/test/diplomacy_panel_narrow_layout_test.dart',
  'app/test/diplomacy_panel_orders_test.dart',
  'app/test/diplomacy_panel_rows_test.dart',
  'app/test/diplomacy_panel_test.dart',
  'app/test/diplomacy_screen_320dp_min_viewport_test.dart',
  'app/test/diplomacy_screen_test.dart',
  'app/test/diplomacy_screen_top_bar_test.dart',
  'app/test/game_map_area_event_feed_test.dart',
  'app/test/game_map_area_region_minimap_test.dart',
  'app/test/game_map_area_selection_mode_test.dart',
  'app/test/game_map_area_shell_entry_center_test.dart',
  'app/test/game_map_empire_left_rail_chrome_test.dart',
  'app/test/game_map_empire_left_rail_narrow_test.dart',
  'app/test/game_map_empire_left_rail_test.dart',
  'app/test/game_map_players_bar_narrow_test.dart',
  'app/test/game_map_selection_prompt_dark_tokens_test.dart',
  'app/test/game_screen_320dp_min_viewport_test.dart',
  'app/test/game_screen_branches_test.dart',
  'app/test/game_screen_narrow_test.dart',
  'app/test/game_screen_overture_pending_test.dart',
  'app/test/game_screen_s13_mockup_fidelity_test.dart',
  'app/test/game_screen_side_menu_toggle_test.dart',
  'app/test/game_side_menu_320dp_min_viewport_test.dart',
  'app/test/game_side_menu_test.dart',
  'app/test/grant_or_subsidy_listener_test.dart',
  'app/test/human_draft_projected_region_provider_test.dart',
  'app/test/naval_units_panel_mockup_fidelity_test.dart',
  'app/test/panels_320dp_min_viewport_test.dart',
  'app/test/pause_menu_side_menu_specs_test.dart',
  'app/test/player_turn_event_feed_narrow_inset_test.dart',
  'app/test/production_commodity_breakdown_dialog_320dp_min_viewport_test.dart',
  'app/test/production_commodity_breakdown_dialog_spec_test.dart',
  'app/test/production_commodity_breakdown_dialog_wide_full_width_test.dart',
  'app/test/production_commodity_breakdown_dialog_wide_golden_test.dart',
  'app/test/production_screen_320dp_min_viewport_test.dart',
  'app/test/province_overlay_road_rail_transport_test.dart',
  'app/test/province_overlay_tile_designation_test.dart',
  'app/test/province_overlay_tile_resource_row_dark_token_test.dart',
  'app/test/province_overlay_tile_section_body_rows_dark_tokens_test.dart',
  'app/test/province_overlay_tile_section_dark_tokens_test.dart',
  'app/test/province_overlay_tile_section_remaining_live_data_dark_tokens_test.dart',
  'app/test/province_sea_zone_overlay_detail_paths_test.dart',
  'app/test/shell_game_screen_specs_test.dart',
  'app/test/train_dialogs_goldens_test.dart',
  'app/test/unit_panels_320dp_min_viewport_test.dart',
  'app/test/unit_panels_goldens_test.dart',
  'app/test/unit_panels_widgetbook_dark_chrome_test.dart',
  'app/test/widgetbook_technology_screen_mobile_viewport_test.dart',
};

/// Symbol whose invocation is gated.
const String _kDebugInitSymbol = 'getDebugInitGameResult';

/// Scans `app/test/**/*.dart` and fails when any non-allowlisted file invokes
/// [_kDebugInitSymbol]. Returns 0 on success, 1 on violations.
///
/// [allowlist] overrides the baked-in [_kDebugInitAllowlist] (used by tests).
int runCheckAppTestNoDebugInit(
  String repoRoot, {
  Set<String>? allowlist,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final effectiveAllowlist = allowlist ?? _kDebugInitAllowlist;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI('check_app_test_no_debug_init: app/test not found; nothing to scan.');
    return 0;
  }

  final violations = <String>[];

  final files =
      appTestDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (effectiveAllowlist.contains(relativePath)) {
      continue;
    }
    final content = file.readAsStringSync();
    if (!content.contains(_kDebugInitSymbol)) {
      continue;
    }
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _DebugInitInvocationVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
    );
    parsed.unit.accept(visitor);
    violations.addAll(visitor.sites);
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_debug_init: no disallowed getDebugInitGameResult() '
      'usage found in app/test/**.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_test_no_debug_init: found ${violations.length} disallowed '
    'getDebugInitGameResult() call site(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Use the shared lightweight fixtures in '
    'app/test/support/panel_test_fixtures.dart, a committed serialized '
    'fixture, or add the file to the documented allowlist only when it '
    'genuinely needs generated map/topology data (Refs #3656).',
  );
  return 1;
}

class _DebugInitInvocationVisitor extends RecursiveAstVisitor<void> {
  _DebugInitInvocationVisitor({
    required this.relativePath,
    required this.lineInfo,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> sites = <String>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == _kDebugInitSymbol) {
      final line = lineInfo.getLocation(node.offset).lineNumber;
      sites.add(
        '$relativePath:$line: calls $_kDebugInitSymbol() outside the '
        'documented allowlist.',
      );
    }
    super.visitMethodInvocation(node);
  }
}

void main() {
  exit(runCheckAppTestNoDebugInit(Directory.current.path));
}
