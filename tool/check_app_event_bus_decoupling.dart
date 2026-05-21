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
/// Three sub-checks (any violation flips the rule red):
///
/// 1. Production code under `app/lib/**` (excluding `app/lib/widgetbook/**`)
///    must not call the `AppEventBus()` singleton factory — use the
///    `appEventBusProvider` (or an `AppEventBus.create()` instance held by
///    the owning widget/service) so test containers can dispose without
///    closing the legacy global bus.
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
  // Local by design — `SPEC/program/app-ui-wiring.md` line 84.
  'app/lib/features/game/widgets/civilian_units_panel_support.dart',
  'app/lib/features/game/flame/game_map_area_part1.dart',
  'app/lib/features/game/flame/game_map_area_part2.dart',
  'app/lib/features/game/flame/next_turn_confirmation_dialog.dart',
  'app/lib/features/game/flame/game_screen.dart',
  'app/lib/features/game/widgets/tech_tree_widget.dart',
  'app/lib/features/game/widgets/technology_panel.dart',
  'app/lib/features/shell/new_game_setup_flow.dart',
  // Split / move fleet — `SPEC/program/app-ui-wiring.md` "Split fleet" /
  // "Move fleet" paragraphs.
  'app/lib/features/game/widgets/naval_units_panel.dart',
  // Land armies — `SPEC/program/app-ui-wiring.md` "Land armies" paragraph
  // (split / move army; invasion confirm sub-dialog of move army).
  'app/lib/features/game/widgets/military_units_panel.dart',
  'app/lib/features/game/widgets/move_army_dialog.dart',
  // Deferred per #2626 scope (game-side menu game-parameters dialog and
  // production breakdown). Migrating these to typed bus events is
  // explicitly out of scope for #2626 and must be filed as separate
  // issues before removal from this allow-list.
  'app/lib/features/game/flame/game_side_menu.dart',
  'app/lib/features/game/screens/production_screen.dart',
};

const _scanRoot = 'app/lib';
const _excludedRoot = 'app/lib/widgetbook';
const _featuresRoot = 'app/lib/features';

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

  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p.posix.joinAll(
      p.split(p.relative(entity.path, from: root)),
    );
    if (relativePath.startsWith('$_excludedRoot/')) {
      continue;
    }
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
  }

  final total = singletonViolations.length +
      navigatorKeyViolations.length +
      dialogViolations.length;
  if (total == 0) {
    logI('check_app_event_bus_decoupling: no violations found.');
    return 0;
  }
  logE(
    'check_app_event_bus_decoupling: found $total violation(s):',
  );
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
    super.visitMethodInvocation(node);
  }

  String _format(int offset) {
    final loc = lineInfo.getLocation(offset);
    return '$relativePath:${loc.lineNumber}';
  }
}

void main() {
  exit(runCheckAppEventBusDecoupling(Directory.current.path));
}
