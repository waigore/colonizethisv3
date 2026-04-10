// Development Screen: manage civilian unit work orders. SPEC/tui/screens/development.md.

import 'package:ctterm/package_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/widgets/map_grid_widget.dart';
import 'package:ctterm/map_tui_mapping.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = packageLogger();

/// Valid work targets per spec: work target id -> display label.
const _validWorkTargets = {
  'build_improvement': 'Build Improvement',
  'build_road': 'Build Road',
  'build_port': 'Build Port',
  'build_fort': 'Build Fort',
  'build_rail': 'Build Railroad',
  'upgrade_town': 'Upgrade Town',
};

/// Keyboard mapping for work-type selection: key -> work target id.
///
/// Note: lower-case `r` = build_road, upper-case `R` = build_rail.
const Map<String, String> _workKeyToTarget = {
  'i': 'build_improvement',
  'I': 'build_improvement',
  'r': 'build_road',
  'p': 'build_port',
  'P': 'build_port',
  'f': 'build_fort',
  'F': 'build_fort',
  'R': 'build_rail',
  'u': 'upgrade_town',
  'U': 'upgrade_town',
};

/// Primary hotkey per work target id for display in Available Work.
const Map<String, String> _targetToPrimaryKey = {
  'build_improvement': 'i',
  'build_road': 'r',
  'build_port': 'p',
  'build_fort': 'f',
  'build_rail': 'R',
  'upgrade_town': 'u',
};

/// Development screen for managing civilian unit work orders.
class DevelopmentScreen extends StatefulComponent {
  const DevelopmentScreen({
    super.key,
    required this.game,
    required this.orders,
    this.tileMapByRegion,
    this.combinedTopology,
    required this.onNavigate,
    required this.onOrdersChanged,
    this.onCancelUnitWork,
  });

  /// Current game state (required for unit data).
  final Game game;

  /// Current orders for the human player.
  final Orders orders;

  /// Tile maps by region for map context (mini-map).
  final Map<String, TileMapResult>? tileMapByRegion;

  /// Combined topology for order validation.
  final MapTopology? combinedTopology;
  final void Function(CttermRoute) onNavigate;

  /// Callback when orders are changed (to propagate to game).
  final void Function(Orders) onOrdersChanged;

  /// Callback to clear a unit's in-progress work (currentWork). SPEC/tui/screens/development.md § Cancel Work Order.
  final void Function(String unitId)? onCancelUnitWork;

  @override
  State<DevelopmentScreen> createState() => _DevelopmentScreenState();
}

enum _DevelopmentInputMode { idle, selectingProvince, selectingTile }

class _DevelopmentScreenState extends State<DevelopmentScreen> {
  static const int _maxProvincesVisible = 5;
  static const int _maxTilesVisible = 6;

  /// Currently selected unit index in the list.
  int _selectedIndex = 0;

  /// Current input mode for keyboard handling.
  _DevelopmentInputMode _inputMode = _DevelopmentInputMode.idle;

  /// Work target id currently selected while in selectingWorkType/selectingTile.
  String? _pendingWorkTarget;

  /// Candidate provinces (full province ids) that have at least one eligible tile.
  List<String> _candidateProvinces = const [];

  /// Province id -> candidate tile keys for that province.
  Map<String, List<String>> _candidateTilesByProvince = const {};

  /// Currently selected province index when in province/tile selection flow.
  int _selectedProvinceIndex = 0;

  /// Currently selected tile index within the selected province's tile list.
  int _selectedTileIndexWithinProvince = 0;

  /// Sliding-window start index for the province list when there are more
  /// provinces than can be shown at once.
  int _provinceWindowStart = 0;

  /// Sliding-window start index for the tile list within the current province
  /// when there are more tiles than can be shown at once.
  int _tileWindowStart = 0;

  /// Feedback message to display (e.g., order accepted/rejected).
  String _feedbackMessage = '';

  /// Color for feedback message.
  Color _feedbackColor = Colors.white;

  /// Check if a unit is a civilian unit (Builder, Engineer).
  bool _isCivilianUnit(Unit unit) {
    final type = unit.type.toLowerCase();
    return type.contains('builder') || type.contains('engineer');
  }

  /// Get all civilian units for the human player.
  List<Unit> get _playerCivilianUnits {
    final humanPlayerId = _getHumanPlayerId();
    if (humanPlayerId == null) return [];

    // Civilian units are Builders and Engineers
    final allUnits = <Unit>[];
    allUnits.addAll(
      component.game.worldState.oldWorld.units.where(
        (u) => u.ownerId == humanPlayerId && _isCivilianUnit(u),
      ),
    );
    allUnits.addAll(
      component.game.worldState.newWorld.units.where(
        (u) => u.ownerId == humanPlayerId && _isCivilianUnit(u),
      ),
    );
    return allUnits;
  }

  /// Get the human player's ID (non-AI controlled).
  String? _getHumanPlayerId() {
    for (final entry in component.game.aiControlByGpId.entries) {
      if (!entry.value) return entry.key;
    }
    // Fallback: first player
    return component.game.players.isNotEmpty
        ? component.game.players.first.id
        : null;
  }

  String _provinceLabel(String fullProvinceId) {
    final world = component.game.worldState;
    for (final p in world.oldWorld.provinces) {
      if (p.id == fullProvinceId) {
        return p.displayName ?? p.id;
      }
    }
    for (final p in world.newWorld.provinces) {
      if (p.id == fullProvinceId) {
        return p.displayName ?? p.id;
      }
    }
    return fullProvinceId;
  }

  /// Get province name for a unit using its effective location province id.
  String _getProvinceName(Unit unit) {
    final playerId = _getHumanPlayerId();
    final projected = playerId == null
        ? unit.tileKey
        : projectedCivilianTileKey(
            unit: unit,
            playerId: playerId,
            orders: component.orders,
          );
    final fullProvinceId =
        Unit.provinceIdFromTileKey(projected) ?? unit.locationProvinceId;
    return _provinceLabel(fullProvinceId);
  }

  /// Get the current player's work orders for civilian units.
  List<WorkOrder> _getPlayerWorkOrders() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return [];
    return component.orders.workOrdersByPlayerId[playerId] ?? [];
  }

  /// Get work order for a specific unit, if any.
  WorkOrder? _getWorkOrderForUnit(String unitId) {
    return _getPlayerWorkOrders().where((o) => o.unitId == unitId).firstOrNull;
  }

  /// Check if a unit has pending work orders.
  bool _unitHasWorkOrder(String unitId) {
    return _getWorkOrderForUnit(unitId) != null;
  }

  /// True if unit has work to cancel: pending order or in-progress currentWork.
  bool _unitHasWork(Unit unit) {
    return _getWorkOrderForUnit(unit.id) != null || unit.currentWork != null;
  }

  /// Handle keyboard input.
  // Type is inferred from Nocterm's Focusable.onKeyEvent callback
  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final rawChar = event.character;
    final c = rawChar?.toLowerCase();
    final units = _playerCivilianUnits;

    if (units.isEmpty) {
      if (c == 'escape') {
        component.onNavigate(CttermRoute.inGameShell);
        return true;
      }
      return false;
    }

    // Escape: back to shell or cancel input mode
    if (key == LogicalKey.escape) {
      if (_inputMode == _DevelopmentInputMode.selectingTile) {
        // Step back to province selection.
        setState(() {
          _inputMode = _DevelopmentInputMode.selectingProvince;
          _feedbackMessage =
              'Select province [↑/↓/j/k]nav [Enter]tiles [Esc]back';
          _feedbackColor = Colors.cyan;
        });
        return true;
      }
      if (_inputMode == _DevelopmentInputMode.selectingProvince) {
        // Step back to idle navigation.
        setState(() {
          _inputMode = _DevelopmentInputMode.idle;
          _pendingWorkTarget = null;
          _candidateProvinces = const [];
          _candidateTilesByProvince = const {};
          _selectedProvinceIndex = 0;
          _selectedTileIndexWithinProvince = 0;
          _provinceWindowStart = 0;
          _tileWindowStart = 0;
          _feedbackMessage = '';
        });
        _log.d('cancelled development input mode');
        return true;
      }
      // Idle: leave Development screen back to in-game shell.
      component.onNavigate(CttermRoute.inGameShell);
      return true;
    }

    // Province or tile selection modes: handle navigation and confirmation separately.
    if (_inputMode == _DevelopmentInputMode.selectingProvince) {
      return _handleProvinceSelectionKey(event);
    }
    if (_inputMode == _DevelopmentInputMode.selectingTile) {
      return _handleTileSelectionKey(event, units);
    }

    // Navigation: arrow keys / j/k to navigate unit list
    if (key == LogicalKey.arrowUp || c == 'k') {
      setState(
        () => _selectedIndex = (_selectedIndex - 1).clamp(0, units.length - 1),
      );
      return true;
    }
    if (key == LogicalKey.arrowDown || c == 'j') {
      setState(
        () => _selectedIndex = (_selectedIndex + 1).clamp(0, units.length - 1),
      );
      return true;
    }

    if (_handleIdleActionKey(c, rawChar, units)) {
      return true;
    }

    return false;
  }

  bool _handleIdleActionKey(String? c, String? rawChar, List<Unit> units) {
    // Enter/Space: soft hint only; actual work-type choice is via hotkeys
    // tied to Available Work. Do not change mode here.
    if (_inputMode == _DevelopmentInputMode.idle &&
        (c == null && (rawChar == null))) {
      return false;
    }

    // x: cancel work order for selected unit (from idle mode only, when unit has work)
    if (_inputMode == _DevelopmentInputMode.idle && c == 'x') {
      final unit = units[_selectedIndex];
      if (_unitHasWork(unit)) {
        _cancelWorkOrder(unit);
      }
      return true;
    }

    // Direct work target keys (even without Enter): start work-type + tile selection.
    if (_inputMode == _DevelopmentInputMode.idle && rawChar != null) {
      final target = _workKeyToTarget[rawChar];
      if (target != null) {
        final unit = units[_selectedIndex];
        if (!_unitHasWorkOrder(unit.id)) {
          _startTileSelection(unit, target);
          return true;
        }
      }
    }

    // Enter/Space: handled last so they remain a soft hint when idle.
    if (_inputMode == _DevelopmentInputMode.idle &&
        (c == null || c.isEmpty) &&
        (rawChar == null || rawChar.isEmpty)) {
      return false;
    }

    return false;
  }

  /// Begin tile-selection mode for [unit] and [target].
  void _startTileSelection(Unit unit, String target) {
    final byProvince = _candidateTilesByProvinceFor(unit, target);
    if (byProvince.isEmpty) {
      setState(() {
        _inputMode = _DevelopmentInputMode.idle;
        _pendingWorkTarget = null;
        _candidateProvinces = const [];
        _candidateTilesByProvince = const {};
        _selectedProvinceIndex = 0;
        _selectedTileIndexWithinProvince = 0;
        _feedbackMessage =
            'No eligible tiles for ${_getWorkTargetName(target)}';
        _feedbackColor = Colors.yellow;
      });
      _log.d('no eligible tiles for $target and unit ${unit.id}');
      return;
    }

    final provinces = byProvince.keys.toList();
    provinces.sort();
    final builderProvince = unit.locationProvinceId;
    var initialProvinceIndex = 0;
    if (builderProvince.isNotEmpty) {
      final idx = provinces.indexOf(builderProvince);
      if (idx >= 0) {
        initialProvinceIndex = idx;
      }
    }

    setState(() {
      _inputMode = _DevelopmentInputMode.selectingProvince;
      _pendingWorkTarget = target;
      _candidateProvinces = provinces;
      _candidateTilesByProvince = byProvince;
      _selectedProvinceIndex = initialProvinceIndex;
      _selectedTileIndexWithinProvince = 0;
      _provinceWindowStart = 0;
      _tileWindowStart = 0;
      _feedbackMessage = 'Select province [↑/↓/j/k]nav [Enter]tiles [Esc]back';
      _feedbackColor = Colors.cyan;
    });
    _log.d('selecting province/tile for $target and unit ${unit.id}');
  }

  /// Ensure the province sliding window keeps the selected province visible.
  void _updateProvinceWindow(int windowSize) {
    if (_candidateProvinces.isEmpty || windowSize <= 0) {
      _provinceWindowStart = 0;
      return;
    }
    final total = _candidateProvinces.length;
    final maxStart = (total - windowSize) < 0 ? 0 : (total - windowSize);
    if (_selectedProvinceIndex < _provinceWindowStart) {
      _provinceWindowStart = _selectedProvinceIndex;
    } else if (_selectedProvinceIndex >= _provinceWindowStart + windowSize) {
      _provinceWindowStart = _selectedProvinceIndex - windowSize + 1;
    }
    if (_provinceWindowStart < 0) {
      _provinceWindowStart = 0;
    } else if (_provinceWindowStart > maxStart) {
      _provinceWindowStart = maxStart;
    }
  }

  /// Ensure the tile sliding window for the current province keeps the selected
  /// tile visible.
  void _updateTileWindowForCurrentProvince(int windowSize) {
    if (_candidateProvinces.isEmpty ||
        _candidateTilesByProvince.isEmpty ||
        windowSize <= 0) {
      _tileWindowStart = 0;
      return;
    }
    final provinceIndex = _selectedProvinceIndex.clamp(
      0,
      _candidateProvinces.length - 1,
    );
    final provinceId = _candidateProvinces[provinceIndex];
    final tiles = _candidateTilesByProvince[provinceId] ?? const <String>[];
    if (tiles.isEmpty) {
      _tileWindowStart = 0;
      return;
    }
    final total = tiles.length;
    final maxStart = (total - windowSize) < 0 ? 0 : (total - windowSize);
    final clampedSelected = _selectedTileIndexWithinProvince.clamp(
      0,
      total - 1,
    );

    if (clampedSelected < _tileWindowStart) {
      _tileWindowStart = clampedSelected;
    } else if (clampedSelected >= _tileWindowStart + windowSize) {
      _tileWindowStart = clampedSelected - windowSize + 1;
    }
    if (_tileWindowStart < 0) {
      _tileWindowStart = 0;
    } else if (_tileWindowStart > maxStart) {
      _tileWindowStart = maxStart;
    }
  }

  /// Handle keys while in province-selection mode.
  // ignore: strict_top_level_inference
  bool _handleProvinceSelectionKey(event) {
    final key = event.logicalKey;
    final rawChar = event.character;
    final c = rawChar?.toLowerCase();

    if (_candidateProvinces.isEmpty) {
      setState(() {
        _inputMode = _DevelopmentInputMode.idle;
        _pendingWorkTarget = null;
      });
      return true;
    }

    final lastIndex = _candidateProvinces.length - 1;

    // Navigation within province list.
    if (key == LogicalKey.arrowUp || c == 'k') {
      setState(() {
        _selectedProvinceIndex = (_selectedProvinceIndex - 1).clamp(
          0,
          lastIndex,
        );
        _selectedTileIndexWithinProvince = 0;
        _updateProvinceWindow(_maxProvincesVisible);
        _updateTileWindowForCurrentProvince(_maxTilesVisible);
      });
      return true;
    }
    if (key == LogicalKey.arrowDown || c == 'j') {
      setState(() {
        _selectedProvinceIndex = (_selectedProvinceIndex + 1).clamp(
          0,
          lastIndex,
        );
        _selectedTileIndexWithinProvince = 0;
        _updateProvinceWindow(_maxProvincesVisible);
        _updateTileWindowForCurrentProvince(_maxTilesVisible);
      });
      return true;
    }

    // Enter: switch to tile-selection mode for current province.
    if (key == LogicalKey.enter || key == LogicalKey.space) {
      setState(() {
        _inputMode = _DevelopmentInputMode.selectingTile;
        _feedbackMessage =
            'Select tile in province [↑/↓/j/k]nav [Enter]confirm [Esc]back';
        _feedbackColor = Colors.cyan;
        _selectedTileIndexWithinProvince = 0;
        _tileWindowStart = 0;
        _updateTileWindowForCurrentProvince(_maxTilesVisible);
      });
      return true;
    }

    return false;
  }

  /// Handle keys while in tile-selection mode.
  // ignore: strict_top_level_inference
  bool _handleTileSelectionKey(event, List<Unit> units) {
    final key = event.logicalKey;
    final rawChar = event.character;
    final c = rawChar?.toLowerCase();

    if (_candidateProvinces.isEmpty ||
        _candidateTilesByProvince.isEmpty ||
        _pendingWorkTarget == null) {
      // Nothing to select; fall back to idle.
      setState(() {
        _inputMode = _DevelopmentInputMode.idle;
        _pendingWorkTarget = null;
      });
      return true;
    }

    final provinceIndex = _selectedProvinceIndex.clamp(
      0,
      _candidateProvinces.length - 1,
    );
    final provinceId = _candidateProvinces[provinceIndex];
    final tiles = _candidateTilesByProvince[provinceId] ?? const <String>[];
    if (tiles.isEmpty) {
      // No tiles in this province: treat as province selection again.
      setState(() {
        _inputMode = _DevelopmentInputMode.selectingProvince;
        _feedbackMessage =
            'Select province [↑/↓/j/k]nav [Enter]tiles [Esc]back';
        _feedbackColor = Colors.cyan;
      });
      return true;
    }

    final lastTileIndex = tiles.length - 1;

    // Navigation within tile list.
    if (key == LogicalKey.arrowUp || c == 'k') {
      setState(() {
        _selectedTileIndexWithinProvince =
            (_selectedTileIndexWithinProvince - 1).clamp(0, lastTileIndex);
        _updateTileWindowForCurrentProvince(_maxTilesVisible);
      });
      return true;
    }
    if (key == LogicalKey.arrowDown || c == 'j') {
      setState(() {
        _selectedTileIndexWithinProvince =
            (_selectedTileIndexWithinProvince + 1).clamp(0, lastTileIndex);
        _updateTileWindowForCurrentProvince(_maxTilesVisible);
      });
      return true;
    }

    // Confirm selection.
    if (key == LogicalKey.enter || key == LogicalKey.space) {
      final unit = units[_selectedIndex];
      final target = _pendingWorkTarget!;
      final tileKey = tiles[_selectedTileIndexWithinProvince];
      _assignWorkOrder(unit, target, tileKey);
      return true;
    }

    // Escape is handled at top-level; other keys are ignored here.
    return false;
  }

  /// Assign a work order to a unit.
  void _assignWorkOrder(Unit unit, String target, String targetTileKey) {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return;

    // Create new work order with full tile key.
    final order = WorkOrder(
      unitId: unit.id,
      target: target,
      targetTileKey: targetTileKey,
    );

    // Add to existing orders
    final existingOrders =
        component.orders.workOrdersByPlayerId[playerId] ?? [];
    final updatedOrders = <WorkOrder>[
      ...existingOrders..removeWhere((o) => o.unitId == unit.id),
      order,
    ];

    final newOrders = Orders(
      moveOrdersByPlayerId: component.orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: component.orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: {
        ...component.orders.workOrdersByPlayerId,
        playerId: updatedOrders,
      },
      diplomaticOrdersByPlayerId: component.orders.diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: component.orders.researchOrdersByPlayerId,
      navalMoveOrdersByPlayerId: component.orders.navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId:
          component.orders.navalMissionOrdersByPlayerId,
    );

    component.onOrdersChanged(newOrders);

    setState(() {
      _inputMode = _DevelopmentInputMode.idle;
      _pendingWorkTarget = null;
      _candidateProvinces = const [];
      _candidateTilesByProvince = const {};
      _selectedProvinceIndex = 0;
      _selectedTileIndexWithinProvince = 0;
      _provinceWindowStart = 0;
      _tileWindowStart = 0;
      final label = _getWorkTargetName(target);
      final tileLabel = _formatTileLabel(targetTileKey);
      _feedbackMessage = 'Work order assigned: $label at $tileLabel';
      _feedbackColor = Colors.green;
    });

    _log.d('assigned $target to unit ${unit.id}');
  }

  /// Cancel work for a unit: remove pending order and/or clear in-progress currentWork.
  void _cancelWorkOrder(Unit unit) {
    final unitId = unit.id;
    final playerId = _getHumanPlayerId();
    if (playerId == null) return;

    final existingOrders =
        component.orders.workOrdersByPlayerId[playerId] ?? [];
    final updatedOrders = existingOrders
        .where((o) => o.unitId != unitId)
        .toList();
    final newOrders = Orders(
      moveOrdersByPlayerId: component.orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: component.orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: {
        ...component.orders.workOrdersByPlayerId,
        playerId: updatedOrders,
      },
      diplomaticOrdersByPlayerId: component.orders.diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: component.orders.researchOrdersByPlayerId,
      navalMoveOrdersByPlayerId: component.orders.navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId:
          component.orders.navalMissionOrdersByPlayerId,
    );
    component.onOrdersChanged(newOrders);

    if (unit.currentWork != null) {
      component.onCancelUnitWork?.call(unitId);
    }

    setState(() {
      _feedbackMessage = 'Work order cancelled (no refund)';
      _feedbackColor = Colors.yellow;
    });

    _log.d('cancelled work order for unit $unitId');
  }

  /// Get display name for work target.
  String _getWorkTargetName(String target) {
    return _validWorkTargets[target] ?? target;
  }

  /// Compute candidate tiles grouped by province for a unit and work target.
  ///
  /// Uses the logic package's getValidWorkOrderTileKeysWithVisibility for
  /// visibility-aware tile filtering, then applies UI-specific filters
  /// (reserved tiles, resources).
  Map<String, List<String>> _candidateTilesByProvinceFor(
    Unit unit,
    String target,
  ) {
    final game = component.game;
    final world = game.worldState;
    final playerId = _getHumanPlayerId();
    if (playerId == null) {
      return const {};
    }

    final topology = component.combinedTopology ?? const MapTopology();
    final view = buildPlayerView(game, topology, playerId);

    final validTileKeys = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: view,
      unitId: unit.id,
      workTarget: target,
      currentOrders: component.orders,
      tileMapByRegion: component.tileMapByRegion,
    );

    final byProvince = <String, List<String>>{};

    // Per-player tile exclusivity (Builder, Engineer, Merchant) — match core logic:
    // exclude tiles that already have active or newly assigned development/purchase
    // work for this player so the UI does not offer invalid targets.
    final reservedTiles = <String>{};

    // Existing multi-turn work (currentWork) for Builder/Engineer/Merchant units.
    bool isDevExclusiveUnitType(String type) =>
        type == 'Builder' || type == 'Engineer' || type == 'Merchant';

    for (final u in world.oldWorld.units) {
      final w = u.currentWork;
      if (u.ownerId == playerId &&
          isDevExclusiveUnitType(u.type) &&
          w != null &&
          w.tileKey.isNotEmpty) {
        reservedTiles.add(w.tileKey);
      }
    }
    for (final u in world.newWorld.units) {
      final w = u.currentWork;
      if (u.ownerId == playerId &&
          isDevExclusiveUnitType(u.type) &&
          w != null &&
          w.tileKey.isNotEmpty) {
        reservedTiles.add(w.tileKey);
      }
    }

    // Pending work orders for this player for dev-exclusive targets.
    bool isDevExclusiveTarget(String t) =>
        t == 'build_improvement' ||
        t == 'upgrade_town' ||
        t == 'build_road' ||
        t == 'build_port' ||
        t == 'build_fort' ||
        t == 'purchase_land';

    final existingOrders =
        component.orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
    for (final w in existingOrders) {
      if (isDevExclusiveTarget(w.target)) {
        reservedTiles.add(w.targetTileKey);
      }
    }

    // Group valid tiles by province, applying UI-specific filters.
    for (final tileKey in validTileKeys) {
      if (reservedTiles.contains(tileKey)) {
        continue;
      }

      final parts = tileKey.split('|');
      if (parts.length < 2) continue;
      final regionId = parts[0];
      final provinceId = parts[1];

      // Only allow tiles that are under the player's control (owned province or
      // purchased tile), matching core logic's isTileControlledByPlayer rule.
      if (!isTileControlledByPlayer(game, playerId, tileKey)) {
        continue;
      }

      // For build_improvement, restrict to tiles that actually have a resource,
      // so Builders do not offer improvement work on empty tiles.
      if (target == 'build_improvement') {
        final tileMap = component.tileMapByRegion?[regionId];
        if (tileMap != null && parts.length >= 4) {
          final x = int.tryParse(parts[2]) ?? 0;
          final y = int.tryParse(parts[3]) ?? 0;
          final resource = tileMap.resourceAt(x, y);
          if (resource == null) {
            continue;
          }
        }
      }

      byProvince.putIfAbsent(provinceId, () => []).add(tileKey);
    }

    return byProvince;
  }

  /// Format a tile label from a full tile key regionId|provinceLocalId|x|y,
  /// including terrain and resource glyphs.
  String _formatTileLabel(String tileKey) {
    final parts = tileKey.split('|');
    if (parts.length < 4) {
      return tileKey;
    }
    final regionId = parts[0];
    final localId = parts[1];
    final x = parts[2];
    final y = parts[3];
    final fullProvinceId = '$regionId|$localId';
    final name = _provinceLabel(fullProvinceId);

    final tileMap = component.tileMapByRegion?[regionId];
    if (tileMap == null) {
      return '$name ($x,$y)';
    }
    final xx = int.tryParse(x) ?? 0;
    final yy = int.tryParse(y) ?? 0;
    final terrain = tileMap.terrainAt(xx, yy);
    final resource = tileMap.resourceAt(xx, yy);
    final terrainChar = terrainToChar(terrain);
    final resourceChar = resourceToChar(resource);
    final resourcePart = resourceChar.isEmpty ? '' : ' $resourceChar';
    return '$name ($x,$y) $terrainChar$resourcePart';
  }

  /// Returns the tile key that should be shown in the mini-map, based on the
  /// current mode and selection (selection takes precedence over existing work).
  String? _currentHighlightedTileKey(Unit unit, WorkOrder? workOrder) {
    // During tile selection, show the currently selected tile.
    if (_inputMode == _DevelopmentInputMode.selectingTile &&
        _candidateProvinces.isNotEmpty &&
        _candidateTilesByProvince.isNotEmpty) {
      final provinceIndex = _selectedProvinceIndex.clamp(
        0,
        _candidateProvinces.length - 1,
      );
      final provinceId = _candidateProvinces[provinceIndex];
      final tiles = _candidateTilesByProvince[provinceId];
      if (tiles != null && tiles.isNotEmpty) {
        final tileIndex = _selectedTileIndexWithinProvince.clamp(
          0,
          tiles.length - 1,
        );
        return tiles[tileIndex];
      }
    }
    // During province selection, show the first tile of the selected province
    // to give context about where we're selecting work.
    if (_inputMode == _DevelopmentInputMode.selectingProvince &&
        _candidateProvinces.isNotEmpty &&
        _candidateTilesByProvince.isNotEmpty) {
      final provinceIndex = _selectedProvinceIndex.clamp(
        0,
        _candidateProvinces.length - 1,
      );
      final provinceId = _candidateProvinces[provinceIndex];
      final tiles = _candidateTilesByProvince[provinceId];
      if (tiles != null && tiles.isNotEmpty) {
        // Show the first tile of the selected province as the mini-map center.
        return tiles.first;
      }
    }
    if (workOrder != null && workOrder.targetTileKey.isNotEmpty) {
      return workOrder.targetTileKey;
    }
    if (unit.currentWork != null && unit.currentWork!.tileKey.isNotEmpty) {
      return unit.currentWork!.tileKey;
    }
    final playerId = _getHumanPlayerId();
    if (playerId == null) return null;
    return projectedCivilianTileKey(
      unit: unit,
      playerId: playerId,
      orders: component.orders,
    );
  }

  /// Build a small resources-layer mini map centered on [tileKey] when tile maps
  /// are available for the tile's region.
  Component _buildMiniMap(String tileKey) {
    final parts = tileKey.split('|');
    if (parts.length < 4) {
      return const SizedBox.shrink();
    }
    final regionId = parts[0];
    final x = int.tryParse(parts[2]) ?? 0;
    final y = int.tryParse(parts[3]) ?? 0;

    final tileMap = component.tileMapByRegion?[regionId];
    if (tileMap == null) {
      return const SizedBox.shrink();
    }

    const viewportWidth = 14;
    const viewportHeight = 4;

    final maxX = tileMap.width - viewportWidth;
    final maxY = tileMap.height - viewportHeight;
    final clampedMaxX = maxX < 0 ? 0 : maxX;
    final clampedMaxY = maxY < 0 ? 0 : maxY;

    final rawViewX = x - viewportWidth ~/ 2;
    final rawViewY = y - viewportHeight ~/ 2;
    final viewX = rawViewX.clamp(0, clampedMaxX);
    final viewY = rawViewY.clamp(0, clampedMaxY);

    return Container(
      margin: const EdgeInsets.only(top: 1, bottom: 1),
      child: MapGridWidget(
        regionId: regionId,
        tileMap: tileMap,
        game: component.game,
        viewportWidth: viewportWidth,
        viewportHeight: viewportHeight,
        viewX: viewX,
        viewY: viewY,
        layer: MapGridLayer.resources,
      ),
    );
  }

  /// Returns the set of work target ids that are valid for this civilian unit
  /// type, based on SPEC/game/civilian-units.md.
  Set<String> _allowedTargetsFor(Unit unit) {
    final t = unit.type.toLowerCase();
    // Rail Builder: only build_rail.
    if (t.contains('rail')) {
      return {'build_rail'};
    }
    final allowed = <String>{};
    if (t.contains('builder')) {
      allowed.addAll(['build_improvement', 'upgrade_town']);
    }
    if (t.contains('engineer')) {
      allowed.addAll(['build_road', 'build_port', 'build_fort']);
    }
    return allowed;
  }

  @override
  Component build(BuildContext context) {
    final units = _playerCivilianUnits;
    final selectedUnit = units.isNotEmpty ? units[_selectedIndex] : null;
    final workOrder = selectedUnit != null
        ? _getWorkOrderForUnit(selectedUnit.id)
        : null;

    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: const Color(0xFF1a1a2e),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Row(
              children: [
                const Text(
                  ' Development ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' | Civilian Units | ',
                  style: TextStyle(color: Colors.gray),
                ),
                _buildHelpText(),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: units.isEmpty
                ? const Center(
                    child: Text(
                      'No civilian units available',
                      style: TextStyle(color: Colors.gray),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unit list
                      Expanded(flex: 2, child: _buildUnitList(units)),
                      const SizedBox(width: 1),
                      // Detail panel
                      Expanded(
                        flex: 3,
                        child: _buildDetailPanel(selectedUnit, workOrder),
                      ),
                    ],
                  ),
          ),
          // Feedback line
          if (_feedbackMessage.isNotEmpty)
            Container(
              color: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Text(
                // ignore: prefer_interpolation_to_compose_strings
                ' ' + _feedbackMessage,
                style: TextStyle(color: _feedbackColor),
              ),
            ),
        ],
      ),
    );
  }

  /// Build help text for current mode.
  Component _buildHelpText() {
    if (_inputMode == _DevelopmentInputMode.selectingProvince) {
      return const Text(
        '[↑/↓/j/k]nav provinces [Enter]tiles [Esc]back',
        style: TextStyle(color: Colors.cyan),
      );
    }
    if (_inputMode == _DevelopmentInputMode.selectingTile) {
      return const Text(
        '[↑/↓/j/k]nav tiles [Enter]confirm [Esc]back',
        style: TextStyle(color: Colors.cyan),
      );
    }
    return const Text(
      '[↑/↓/j/k]nav [Ent]assign [x]cancel [Esc]back',
      style: TextStyle(color: Colors.gray),
    );
  }

  /// Build the civilian unit list.
  Component _buildUnitList(List<Unit> units) {
    return Container(
      color: const Color(0xFF0d0d1a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            color: const Color(0xFF1a1a2e),
            child: const Text(
              ' UNIT ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                final isSelected = index == _selectedIndex;
                final hasWork = _unitHasWork(unit);
                final workOrder = _getWorkOrderForUnit(unit.id);
                final workTargetName = workOrder != null
                    ? _getWorkTargetName(workOrder.target)
                    : (unit.currentWork != null
                          ? _getWorkTargetName(unit.currentWork!.workTarget)
                          : null);

                final status = workTargetName ?? 'idle';

                final bg = isSelected ? const Color(0xFF2a2a4e) : null;
                final fg = isSelected ? Colors.white : Colors.gray;

                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 1,
                    vertical: 0,
                  ),
                  child: Row(
                    children: [
                      if (isSelected)
                        const Text('> ', style: TextStyle(color: Colors.yellow))
                      else
                        const Text('  '),
                      Expanded(
                        child: Text(
                          '${unit.type} @ ${_getProvinceName(unit)}',
                          style: TextStyle(color: fg),
                        ),
                      ),
                      Text(
                        hasWork
                            ? '[${status.substring(0, status.length.clamp(0, 8))}]'
                            : '[idle]',
                        style: TextStyle(
                          color: hasWork ? Colors.cyan : Colors.gray,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the detail panel for selected unit.
  Component _buildDetailPanel(Unit? unit, WorkOrder? workOrder) {
    if (unit == null) {
      return Container(
        color: const Color(0xFF0d0d1a),
        child: const Center(
          child: Text(
            'Select a unit to view details',
            style: TextStyle(color: Colors.gray),
          ),
        ),
      );
    }

    final highlightedTileKey = _currentHighlightedTileKey(unit, workOrder);
    final allowedTargets = _allowedTargetsFor(unit);

    return Container(
      color: const Color(0xFF0d0d1a),
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit header
          Container(
            width: double.infinity,
            color: const Color(0xFF1a1a2e),
            padding: const EdgeInsets.all(1),
            child: Text(
              ' ${unit.type.toUpperCase()} ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 1),
          // Unit details
          const SizedBox(height: 1),
          _buildDetailRow('Unit ID', unit.id),
          _buildDetailRow('Location', _getProvinceName(unit)),
          _buildDetailRow(
            'Type',
            _isCivilianUnit(unit) ? 'Civilian' : 'Military',
          ),
          _buildDetailRow(
            'Status',
            (workOrder != null || unit.currentWork != null)
                ? 'Working'
                : 'Idle',
          ),
          if (workOrder != null || unit.currentWork != null) ...[
            const SizedBox(height: 1),
            _buildDetailRow(
              'Work Target',
              _getWorkTargetName(
                workOrder?.target ?? unit.currentWork!.workTarget,
              ),
            ),
            _buildDetailRow(
              'Target Tile',
              _formatTileLabel(
                workOrder?.targetTileKey ?? unit.currentWork!.tileKey,
              ),
            ),
          ],
          const SizedBox(height: 1),
          // Lower area: split horizontally between text lists (available work
          // + province/tile tree) and mini-map, and cap list lengths so the
          // whole panel stays within 80x24.
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Available Work and province/tile tree (only while assigning).
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (workOrder == null) ...[
                        const Text(
                          ' Available Work: ',
                          style: TextStyle(color: Colors.white),
                        ),
                        for (final entry in _validWorkTargets.entries)
                          Padding(
                            padding: const EdgeInsets.only(left: 1),
                            child: Text(
                              '[${_targetToPrimaryKey[entry.key] ?? '?'}] ${entry.value}',
                              style: TextStyle(
                                color: allowedTargets.contains(entry.key)
                                    ? Colors.white
                                    : Colors.gray,
                              ),
                            ),
                          ),
                        const SizedBox(height: 1),
                        if ((_inputMode ==
                                    _DevelopmentInputMode.selectingProvince ||
                                _inputMode ==
                                    _DevelopmentInputMode.selectingTile) &&
                            _candidateProvinces.isNotEmpty) ...[
                          const Text(
                            ' Provinces: ',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 1),
                          ...() {
                            final total = _candidateProvinces.length;
                            final windowSize = _maxProvincesVisible;
                            final maxStart = (total - windowSize) < 0
                                ? 0
                                : (total - windowSize);
                            final start = _provinceWindowStart.clamp(
                              0,
                              maxStart,
                            );
                            final end = (start + windowSize) > total
                                ? total
                                : (start + windowSize);

                            final components = <Component>[];

                            if (start > 0) {
                              components.add(
                                const Padding(
                                  padding: EdgeInsets.only(left: 1),
                                  child: Text(
                                    '...',
                                    style: TextStyle(color: Colors.gray),
                                  ),
                                ),
                              );
                            }

                            for (var i = start; i < end; i++) {
                              final isSelected = i == _selectedProvinceIndex;
                              components.add(
                                Padding(
                                  padding: const EdgeInsets.only(left: 1),
                                  child: Text(
                                    '${isSelected ? '>' : ' '} ${_provinceLabel(_candidateProvinces[i])}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.cyan
                                          : Colors.gray,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (end < total) {
                              components.add(
                                const Padding(
                                  padding: EdgeInsets.only(left: 1),
                                  child: Text(
                                    '...',
                                    style: TextStyle(color: Colors.gray),
                                  ),
                                ),
                              );
                            }

                            return components;
                          }(),
                          const SizedBox(height: 1),
                          const Text(
                            ' Tiles: ',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 1),
                          if (_candidateProvinces.isNotEmpty)
                            ...() {
                              final provinceIndex = _selectedProvinceIndex
                                  .clamp(0, _candidateProvinces.length - 1);
                              final provinceId =
                                  _candidateProvinces[provinceIndex];
                              final tiles =
                                  _candidateTilesByProvince[provinceId] ??
                                  const <String>[];
                              if (tiles.isEmpty) return <Component>[];
                              final totalTiles = tiles.length;
                              final windowSize = _maxTilesVisible;
                              final maxStart = (totalTiles - windowSize) < 0
                                  ? 0
                                  : (totalTiles - windowSize);
                              final start = _tileWindowStart.clamp(0, maxStart);
                              final end = (start + windowSize) > totalTiles
                                  ? totalTiles
                                  : (start + windowSize);
                              final selectedTileIndex =
                                  _selectedTileIndexWithinProvince.clamp(
                                    0,
                                    totalTiles - 1,
                                  );

                              final components = <Component>[];

                              if (start > 0) {
                                components.add(
                                  const Padding(
                                    padding: EdgeInsets.only(left: 1),
                                    child: Text(
                                      '...',
                                      style: TextStyle(color: Colors.gray),
                                    ),
                                  ),
                                );
                              }

                              for (var i = start; i < end; i++) {
                                final isSelected = i == selectedTileIndex;
                                components.add(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 1),
                                    child: Text(
                                      '${isSelected ? '>' : ' '} ${_formatTileLabel(tiles[i])}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.cyan
                                            : Colors.gray,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              if (end < totalTiles) {
                                components.add(
                                  const Padding(
                                    padding: EdgeInsets.only(left: 1),
                                    child: Text(
                                      '...',
                                      style: TextStyle(color: Colors.gray),
                                    ),
                                  ),
                                );
                              }

                              return components;
                            }(),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 1),
                // Right side: mini-map (resources view), when we have a tile.
                Expanded(
                  flex: 2,
                  child: highlightedTileKey != null
                      ? _buildMiniMap(highlightedTileKey)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Current mode hint (also surfaced in header help text)
          if (_inputMode == _DevelopmentInputMode.selectingProvince)
            Container(
              width: double.infinity,
              color: const Color(0xFF2a2a4e),
              padding: const EdgeInsets.all(1),
              child: const Text(
                ' Select province... ',
                style: TextStyle(color: Colors.cyan),
              ),
            )
          else if (_inputMode == _DevelopmentInputMode.selectingTile)
            Container(
              width: double.infinity,
              color: const Color(0xFF2a2a4e),
              padding: const EdgeInsets.all(1),
              child: const Text(
                ' Select work tile... ',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
        ],
      ),
    );
  }

  /// Build a detail row.
  Component _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 1),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.gray)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
