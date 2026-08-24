import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// Enforces the `AppEventBus` / `appNavigatorKey` decoupling architecture in
/// `app/lib/**` (Refs #2626).
///
/// SPEC source of truth:
/// - `SPEC/program/app-ui-wiring.md` (when to use the bus vs local Flutter
///   APIs; documented local-by-design dialog/sheet carve-outs).
/// - `SPEC/program/app-event-bus.md` (bus API and `AppEventBus.create`).
///
/// Four sub-checks (any violation flips the rule red):
///
/// 1. Production code under `app/lib/**` must not call the `AppEventBus()`
///    singleton factory — use the `appEventBusProvider` (or an
///    `AppEventBus.create()` instance held by the owning widget/service) so
///    test containers can dispose without closing the legacy global bus.
///    Widgetbook catalog stories live under `widgetbook_host/lib/catalogs/`
///    and are outside this scan root.
///
/// 2. `appNavigatorKey.currentContext`, `appNavigatorKey.currentState`, and
///    any other property access on `appNavigatorKey` is restricted to
///    `app/lib/core/services/**` and `app/lib/app.dart`. Other layers must
///    thread an explicit `GlobalKey<NavigatorState>` parameter or use the
///    bus, so the global lookup stays hidden behind the documented choke
///    point.
///
/// 3. Inside `app/lib/features/**` (which covers `features/shell/**`,
///    `features/game/widgets/**`, `features/game/flame/**`, and feature
///    screens), `showDialog` / `showModalBottomSheet` invocations are
///    restricted to a documented allow-list of local-by-design files
///    (`SPEC/program/app-ui-wiring.md` § "Local by design" plus the per-panel
///    carve-outs for split / move fleet, move army, train at-capital). Any
///    new call site outside that allow-list is a violation; emit a typed
///    `AppEvent` via `AppEventBus` instead.
///
/// 4. Inside `app/lib/features/**`, a `addPostFrameCallback` closure must not
///    emit a non-`ClosePanelEvent` bus event (`bus.emit(...)` /
///    `widget.bus.emit(...)`). That "close the panel, then emit a follow-up
///    event next frame" idiom must route through the shared
///    `AppEventBusPanelNav.closePanelThenEmit` helper
///    (`app/lib/core/services/app_event_bus_panel_nav.dart`) so the
///    SPEC-normative ordering and post-frame rationale live in one place
///    (`SPEC/program/app-ui-wiring.md`). A bare deferred `ClosePanelEvent`
///    emit (for example a scoped auto-close once a panel becomes empty) is
///    still allowed.

const _disallowedSingletonName = 'AppEventBus';

const Set<String> _appNavigatorKeyAllowedPathPrefixes = <String>{
  'app/lib/core/services/',
  'app/lib/app.dart',
};

/// Files under `app/lib/features/**` that may keep `showDialog` /
/// `showModalBottomSheet` calls per `SPEC/program/app-ui-wiring.md`
/// § "Local by design" (line 84) plus per-panel carve-outs documented
/// elsewhere in that file. Each entry should map to one SPEC paragraph
/// (referenced in the trailing comment) so the gate stays auditable.
const Set<String> _allowedFeatureLocalDialogFiles = <String>{
  // Work-target assignment bottom sheet in civilian unit row part file.
  // Same local-by-design rationale as the parent panel —
  // `SPEC/program/app-ui-wiring.md` § "Local by design" (Refs #3878 Phase 3).
  'app/lib/features/game/widgets/units/civilian/civilian_units_panel_support_unit_row_actions.dart',
  // Work-target assignment bottom sheet moved into `civilian_units_panel_unit_row.dart`
  // during wave-9 de-part (Refs #4117). Same local-by-design rationale as
  // `civilian_units_panel_support_unit_row_actions.dart`.
  'app/lib/features/game/widgets/units/civilian/civilian_units_panel_unit_row.dart',
  // Next-turn processing dialog (`_onNextTurn`) and the map display-options
  // dialog (`build`) — the two `showDialog` sites kept after the #3699 Theme 3
  // domain re-split of `game_map_area` (formerly game_map_area_part1/part2).
  // Paths updated when `game_map_area` parts moved under `flame/map_state/`
  // (Refs #3878 Phase 3).
  'app/lib/features/game/flame/map_state/game_map_area_turn_resolution.dart',
  'app/lib/features/game/flame/map_state/game_map_area_build.dart',
  // Map display-options dialog split from `game_map_area_build.dart` into
  // `game_map_area_build_map_stack.dart` for Phase 3 flame map modularization.
  // Same local-by-design rationale as the parent part (Refs #3878 Phase 3).
  'app/lib/features/game/flame/map_state/game_map_area_build_map_stack.dart',
  'app/lib/features/game/flame/overlays/next_turn_confirmation_dialog.dart',
  'app/lib/features/game/screens/game/game_screen.dart',
  // Next-turn processing dialog split from `game_screen.dart` into
  // `game_screen_fallback_next_turn.dart` and isolate runner
  // `game_screen_fallback_next_turn_resolution.dart` for Phase 3 flame
  // modularization. Same local-by-design rationale as the parent file
  // (Refs #3878 Phase 3).
  'app/lib/features/game/screens/game/game_screen_fallback_next_turn.dart',
  'app/lib/features/game/screens/game/game_screen_fallback_next_turn_runner.dart',
  // Android back / exit-to-main-menu confirm dialog extracted from
  // game_screen.dart per `SPEC/ui/in-game-shell-narrow.md` "Android back
  // confirm". Local by design — `SPEC/program/app-ui-wiring.md` line 84.
  'app/lib/features/game/flame/overlays/exit_confirm_dialog.dart',
  'app/lib/features/game/widgets/technology/tech_tree_widget.dart',
  // Tech detail dialog split from `tech_tree_widget.dart` (Refs #3878).
  'app/lib/features/game/widgets/technology/tech_tree_widget_dialog.dart',
  // Shared Tree/Choose-tech detail dialog extracted for #4222 (Refs #4222).
  'app/lib/features/game/widgets/technology/tech_definition_detail_dialog.dart',
  // GP researchers list modal split from tech pennant row / tree surfaces
  // (Refs #3862). Same local-by-design rationale as tech detail in
  // `tech_tree_widget.dart` — `SPEC/program/app-ui-wiring.md` § "Local by design".
  'app/lib/features/game/widgets/technology/tech_researchers_list_dialog.dart',
  'app/lib/features/game/widgets/technology/technology_panel.dart',
  // Bottom-sheet split out of `technology_panel.dart` to keep the panel
  // file under the 700-line `repo.game_widgets_file_size` cap. Same
  // local-by-design rationale as the parent file (Refs #2864 S3 split).
  'app/lib/features/game/widgets/technology/technology_panel_orders.dart',
  // Choose-tech dialog split from `technology_panel_orders.dart` (Refs #3878).
  'app/lib/features/game/widgets/technology/technology_panel_choose_tech_dialog.dart',
  // Read-only research-funding breakdown dialog split out of
  // `technology_panel.dart` to keep that file under the
  // `repo.game_widgets_file_size` cap. Same local-by-design rationale as the
  // parent panel — `SPEC/program/app-ui-wiring.md` § "Local by design"
  // (`ResearchFundingBreakdownDialog`, Refs #3512).
  'app/lib/features/game/widgets/technology/research_slot_turn_preview_view_breakdown.dart',
  'app/lib/features/shell/new_game_setup_flow_dialogs_error.dart',
  'app/lib/features/shell/new_game_setup_flow_dialogs_progress.dart',
  // Split / move fleet — `SPEC/program/app-ui-wiring.md` "Split fleet" /
  // "Move fleet" paragraphs.
  'app/lib/features/game/widgets/units/naval/naval_units_panel.dart',
  // Split / move fleet and home-transfer dialogs extracted from
  // `naval_units_panel.dart` to keep panel parts under the
  // `repo.game_widgets_file_size` cap. Same local-by-design rationale as
  // the parent panel — `SPEC/program/app-ui-wiring.md` § "Local by design"
  // (Refs #3878 Phase 3).
  'app/lib/features/game/widgets/units/naval/naval_units_panel_support_dialogs.dart',
  'app/lib/features/game/widgets/units/naval/naval_units_panel_support_home_transfer.dart',
  // Home-transfer dialog opener split into `naval_units_panel_support_combine.dart`
  // during wave-9 de-part (Refs #4117), then `naval_units_panel_support_combine_home.dart`
  // (Refs #4606). Same local-by-design rationale as
  // `naval_units_panel_support_home_transfer.dart`.
  'app/lib/features/game/widgets/units/naval/naval_units_panel_support_combine.dart',
  'app/lib/features/game/widgets/units/naval/naval_units_panel_support_combine_home.dart',
  // Land armies — `SPEC/program/app-ui-wiring.md` "Land armies" paragraph
  // (split / move army; invasion confirm sub-dialog of move army).
  // Dialog openers extracted from `military_units_panel.dart` to keep panel
  // parts under the `repo.game_widgets_file_size` cap (Refs #3878 Phase 3).
  'app/lib/features/game/widgets/units/military/military_units_panel_dialogs.dart',
  'app/lib/features/game/widgets/unit_orders/move_army_dialog.dart',
  'app/lib/features/game/widgets/unit_orders/move_army_dialog_declare_war.dart',
  // Declare-war confirm `showDialog` lives in state after wave-9 de-part
  // (Refs #4117). Same local-by-design rationale as `move_army_dialog_declare_war.dart`.
  'app/lib/features/game/widgets/unit_orders/move_army_dialog_state.dart',
  // Shared MoveArmyDialog opener + MAP20001 overlay Move/Invade flow
  // (optional DLG20002 army picker). Same local-by-design rationale as
  // `move_army_dialog.dart` / naval mission flow —
  // `SPEC/program/app-ui-wiring.md` Land armies + overlay Move/Invade
  // (Refs #4350).
  'app/lib/features/game/widgets/unit_orders/show_move_army_dialog.dart',
  'app/lib/features/game/widgets/unit_orders/overlay_army_move_flow.dart',
  // MAP20001 overlay Transfer to Home Fleet: optional DLG31003 then DLG40001.
  // Same local-by-design rationale as overlay Move and NavalUnitsPanel home
  // transfer — `SPEC/program/app-ui-wiring.md` § "Local by design" (Refs #4625).
  'app/lib/features/game/widgets/unit_orders/overlay_transfer_to_home_fleet_flow.dart',
  // Home Army detach-then-move: Split then DLG20001 for the new field army.
  // Same local-by-design rationale as overlay Move/Invade (Refs #4407).
  'app/lib/features/game/widgets/unit_orders/home_army_detach_then_move_flow.dart',
  // Home Fleet detach-then-sail: Split then DLG30001 for the new sea-going
  // fleet. Same local-by-design rationale as Home Army detach-then-move —
  // `SPEC/program/app-ui-wiring.md` § "Naval mission (draft wiring)"
  // (Refs #4448).
  'app/lib/features/game/widgets/unit_orders/home_fleet_detach_then_sail_flow.dart',
  // Military Counsel invade Agree reuses the move-army declare-war copy and
  // chrome — same local-by-design rationale as
  // `move_army_dialog_declare_war.dart` (Refs #4307).
  'app/lib/features/game/screens/counsel/counsel_military_invade_confirm.dart',
  // Naval mission / fleet-marker flow — fleet picker / mission menu / target /
  // move `showDialog` steps in `showNavalFleetMarkerFlow` /
  // `showNavalMissionFlow`. Same local-by-design rationale as move fleet —
  // `SPEC/program/app-ui-wiring.md` § "Naval mission (draft wiring)"
  // (Refs #4213, #4343).
  'app/lib/features/game/widgets/unit_orders/naval_mission_flow.dart',
  // Overlay Blockade/Beachhead extracted picker + target confirm helpers
  // (`pickNavalMissionFleetId` / `confirmNavalTargetedMission`). Same
  // local-by-design rationale as `naval_mission_flow.dart`
  // (Refs #4213, #4413).
  'app/lib/features/game/widgets/unit_orders/naval_mission_flow_support.dart',
  // Move Fleet local `showDialog` extracted from `naval_mission_flow.dart`
  // (`showMoveFleetDialogForFleet` / DLG30001). Same local-by-design
  // rationale as the parent flow (Refs #4213, #4343, #4582).
  'app/lib/features/game/widgets/unit_orders/naval_mission_move_dialog.dart',
  // MAP20001 Tile teaching helper — read-only connectivity/port/caption
  // details opened from transport cluster tap or named Tile details action
  // within the province overlay (Refs #4369). Same local-by-design rationale
  // as tech detail / research breakdown dialogs.
  'app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_details.dart',
  // MAP30002 More tile actions — overflow list plus Province details after
  // a map secondary gesture (Refs #4440). Same local-by-design rationale as
  // MAP20001 Tile details — `SPEC/program/app-ui-wiring.md` § "Tile context
  // More dialog".
  'app/lib/features/game/widgets/map_radial/game_map_tile_radial_host.dart',
  // Deferred per #2626 scope (game-side menu game-parameters dialog and
  // production breakdown). Migrating these to typed bus events is
  // explicitly out of scope for #2626 and must be filed as separate
  // issues before removal from this allow-list.
  'app/lib/features/game/flame/controls/game_side_menu.dart',
  'app/lib/features/game/flame/controls/game_side_menu_panel.dart',
  'app/lib/features/game/screens/production/production_screen_body.dart',
  // Production commodity breakdown `showDialog` extracted from
  // `production_screen_body.dart` (`buildProductionScreenPanel`). Same
  // local-by-design rationale as the parent body (Refs #2626, #4606).
  'app/lib/features/game/screens/production/production_screen_body_panel.dart',
};

/// Files allowed to emit a non-[ClosePanelEvent] bus event from inside a
/// `addPostFrameCallback` closure. The shared `closePanelThenEmit` helper
/// (`app/lib/core/services/app_event_bus_panel_nav.dart`) centralizes the
/// "close panel, then emit a follow-up next frame" idiom; feature panels must
/// call the helper instead of re-implementing the post-frame sequencing. The
/// helper itself lives outside `app/lib/features/**` (so it is never scanned by
/// this sub-check), but it is listed here to document intent and stay correct
/// if it ever moves under `features/`.
const Set<String> _allowedPostFrameBusEmitFiles = <String>{
  'app/lib/core/services/app_event_bus_panel_nav.dart',
};

const _scanRoot = 'app/lib';
const _featuresRoot = 'app/lib/features';

const _closePanelEventName = 'ClosePanelEvent';

/// Returns true when [target] looks like an `AppEventBus` reference such as
/// `bus`, `widget.bus`, or `self.bus` (the shapes used by the unit panels).
bool _isBusTarget(Expression? target) {
  if (target is SimpleIdentifier) return target.name == 'bus';
  if (target is PrefixedIdentifier) return target.identifier.name == 'bus';
  if (target is PropertyAccess) return target.propertyName.name == 'bus';
  return false;
}

/// Best-effort syntactic name of the event constructed in `emit(<event>)`.
///
/// `parseString` does not resolve types: `const ClosePanelEvent()` parses as an
/// [InstanceCreationExpression] while `OpenDialogEvent(...)` parses as a bare
/// [MethodInvocation]. Returns null for anything else (for example a variable),
/// which callers treat as non-`ClosePanelEvent` (flagged) to stay conservative.
String? _emittedEventTypeName(Expression arg) {
  if (arg is InstanceCreationExpression) {
    return arg.constructorName.type.name.lexeme;
  }
  if (arg is MethodInvocation && arg.target == null) {
    return arg.methodName.name;
  }
  return null;
}

int runCheckAppEventBusDecoupling(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _scanRoot));
  if (!libDir.existsSync()) {
    logE('check_app_event_bus_decoupling: $_scanRoot not found.');
    return 1;
  }

  final singletonViolations = <String>[];
  final navigatorKeyViolations = <String>[];
  final dialogViolations = <String>[];
  final postFrameBusEmitViolations = <String>[];

  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p.posix.joinAll(
      p.split(p.relative(entity.path, from: root)),
    );
    final content = entity.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _AppEventBusDecouplingVisitor(
      relativePath: relativePath,
      lineInfo: parsed.lineInfo,
    );
    parsed.unit.accept(visitor);
    singletonViolations.addAll(visitor.singletonViolations);
    navigatorKeyViolations.addAll(visitor.navigatorKeyViolations);
    dialogViolations.addAll(visitor.dialogViolations);
    postFrameBusEmitViolations.addAll(visitor.postFrameBusEmitViolations);
  }

  final total =
      singletonViolations.length +
      navigatorKeyViolations.length +
      dialogViolations.length +
      postFrameBusEmitViolations.length;
  if (total == 0) {
    logI('check_app_event_bus_decoupling: no violations found.');
    return 0;
  }
  logE('check_app_event_bus_decoupling: found $total violation(s):');
  if (singletonViolations.isNotEmpty) {
    logE(
      ' AppEventBus() singleton calls (use appEventBusProvider or '
      'AppEventBus.create()):',
    );
    for (final v in singletonViolations) {
      logE(' - $v');
    }
  }
  if (navigatorKeyViolations.isNotEmpty) {
    logE(
      ' appNavigatorKey property access outside core/services/ + app.dart '
      '(thread GlobalKey<NavigatorState> explicitly):',
    );
    for (final v in navigatorKeyViolations) {
      logE(' - $v');
    }
  }
  if (dialogViolations.isNotEmpty) {
    logE(
      ' showDialog / showModalBottomSheet in features/ outside the '
      'documented local-by-design allow-list (emit an AppEvent instead):',
    );
    for (final v in dialogViolations) {
      logE(' - $v');
    }
  }
  if (postFrameBusEmitViolations.isNotEmpty) {
    logE(
      ' addPostFrameCallback closures emitting a non-ClosePanelEvent bus '
      'event in features/ (use AppEventBus.closePanelThenEmit instead):',
    );
    for (final v in postFrameBusEmitViolations) {
      logE(' - $v');
    }
  }
  return 1;
}

class _AppEventBusDecouplingVisitor extends RecursiveAstVisitor<void> {
  _AppEventBusDecouplingVisitor({
    required this.relativePath,
    required this.lineInfo,
  });

  final String relativePath;
  final LineInfo lineInfo;

  final List<String> singletonViolations = <String>[];
  final List<String> navigatorKeyViolations = <String>[];
  final List<String> dialogViolations = <String>[];
  final List<String> postFrameBusEmitViolations = <String>[];

  bool get _appNavigatorKeyAllowed {
    for (final prefix in _appNavigatorKeyAllowedPathPrefixes) {
      if (prefix.endsWith('/')) {
        if (relativePath.startsWith(prefix)) return true;
      } else if (relativePath == prefix) {
        return true;
      }
    }
    return false;
  }

  bool get _isFeatureFile => relativePath.startsWith('$_featuresRoot/');

  bool get _featureFileAllowed =>
      _allowedFeatureLocalDialogFiles.contains(relativePath);

  bool get _postFrameBusEmitAllowed =>
      _allowedPostFrameBusEmitFiles.contains(relativePath);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type;
    final name = type.name.lexeme;
    final ctorName = node.constructorName.name?.name;
    if (name == _disallowedSingletonName && ctorName == null) {
      singletonViolations.add(_format(node.offset));
    }
    super.visitInstanceCreationExpression(node);
  }

  bool _isAppEventBusBareCall(MethodInvocation node) {
    // `parseString` does not resolve types, so `AppEventBus()` is parsed as a
    // MethodInvocation (target == null, methodName == 'AppEventBus') instead
    // of an InstanceCreationExpression. Detect that shape directly. Named
    // constructors such as `AppEventBus.create()` parse as MethodInvocation
    // with target == SimpleIdentifier('AppEventBus'); those must not trigger.
    if (node.target != null) return false;
    if (node.methodName.name != _disallowedSingletonName) return false;
    return node.argumentList.arguments.isEmpty;
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkAppNavigatorKeyAccess(node.prefix, node);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is SimpleIdentifier) {
      _checkAppNavigatorKeyAccess(target, node);
    }
    super.visitPropertyAccess(node);
  }

  void _checkAppNavigatorKeyAccess(SimpleIdentifier target, AstNode node) {
    if (target.name != 'appNavigatorKey') return;
    if (_appNavigatorKeyAllowed) return;
    navigatorKeyViolations.add(_format(node.offset));
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isAppEventBusBareCall(node)) {
      singletonViolations.add(_format(node.offset));
    }
    if (_isFeatureFile && !_featureFileAllowed) {
      final name = node.methodName.name;
      if (name == 'showDialog' || name == 'showModalBottomSheet') {
        // Only flag top-level / library calls (no explicit target other than a
        // package reference). This keeps `someObj.showDialog(...)` overloads
        // from false-positiving; in practice the Flutter free functions have
        // no target.
        if (node.target == null) {
          dialogViolations.add(_format(node.offset));
        }
      }
    }
    if (_isFeatureFile &&
        !_postFrameBusEmitAllowed &&
        node.methodName.name == 'addPostFrameCallback') {
      _collectPostFrameBusEmits(node);
    }
    super.visitMethodInvocation(node);
  }

  /// Flags `bus.emit(<non-ClosePanelEvent>)` calls inside the closure passed to
  /// `addPostFrameCallback`. A deferred bare `ClosePanelEvent` emit is allowed.
  void _collectPostFrameBusEmits(MethodInvocation node) {
    for (final arg in node.argumentList.arguments) {
      if (arg is! FunctionExpression) continue;
      final emitVisitor = _PostFrameBusEmitVisitor();
      arg.body.accept(emitVisitor);
      for (final offset in emitVisitor.offendingEmitOffsets) {
        postFrameBusEmitViolations.add(_format(offset));
      }
    }
  }

  String _format(int offset) {
    final loc = lineInfo.getLocation(offset);
    return '$relativePath:${loc.lineNumber}';
  }
}

/// Collects offsets of `bus.emit(<event>)` calls (within a post-frame closure)
/// whose emitted event is anything other than [ClosePanelEvent].
class _PostFrameBusEmitVisitor extends RecursiveAstVisitor<void> {
  final List<int> offendingEmitOffsets = <int>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'emit' &&
        _isBusTarget(node.target) &&
        node.argumentList.arguments.length == 1) {
      final typeName = _emittedEventTypeName(node.argumentList.arguments.first);
      if (typeName != _closePanelEventName) {
        offendingEmitOffsets.add(node.offset);
      }
    }
    super.visitMethodInvocation(node);
  }
}

void main() {
  exit(runCheckAppEventBusDecoupling(Directory.current.path));
}
