// In-Game Shell: topology graph map + HUD + province info + panel navigation.
// SPEC/tui/ctterm.md, SPEC/tui/screens/in-game-shell.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/widgets/map_grid_widget.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:ctterm/map_tui_mapping.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// In-game shell: topology graph map, HUD, province info panel, navigation to panels.
class InGameShellScreen extends StatefulComponent {
  const InGameShellScreen({
    super.key,
    this.game,
    required this.orders,
    this.combinedTopology,
    this.gameEvents,
    this.tileMapByRegion,
    required this.onNavigate,
    required this.onEndTurn,
    required this.onVictory,
    required this.onDefeat,
    required this.onExitToMainMenu,
  });

  final Game? game;
  /// Current orders for the human player (used for idle-civilian end-turn checks).
  final Orders orders;
  /// Topology for the current game (from save/init). Used for land graph and neighbour navigation.
  final MapTopology? combinedTopology;
  final List<GameEvent>? gameEvents;
  /// Tile maps by region (oldWorld, newWorld) for future map overlays (currently unused in this screen).
  final Map<String, TileMapResult>? tileMapByRegion;
  final void Function(CttermRoute) onNavigate;
  final Future<void> Function() onEndTurn;
  final void Function() onVictory;
  final void Function() onDefeat;
  final void Function() onExitToMainMenu;

  @override
  State<InGameShellScreen> createState() => _InGameShellScreenState();
}

class _InGameShellScreenState extends State<InGameShellScreen> {
  String _selectedRegion = 'oldWorld';
  /// Local province id (in current region) of the selected node in the graph.
  String? _selectedProvinceLocalId;
  /// Index into current province's neighbour list when moving next/prev.
  int _neighbourIndex = 0;
  bool _isEndingTurn = false;
  bool _isConfirmingEndTurn = false;
  int _idleCivilianCountForPrompt = 0;
  /// Map grid layer only; viewport is derived from selected province (SPEC/tui/screens/in-game-shell.md § Map Grid Widget).
  MapGridLayer _mapGridLayer = MapGridLayer.terrain;

  int get _turn => component.game?.worldState.turnState.turnNumber ?? 1;
  int get _year => inGameShellHudYear(component.game, _turn);
  Orders get _orders => component.orders;

  /// Computes the calendar year for the in-game shell HUD using the game's
  /// turn-time mapping per SPEC/game/turn-time-mapping.md.
  int inGameShellHudYear(Game? game, int rawTurn) {
    final mapping = game?.turnTimeMapping;
    return turnToYear(rawTurn, mapping);
  }

  int get _treasury {
    final game = component.game;
    if (game == null) return 0;
    for (final player in game.players) {
      if (!(game.aiControlByGpId[player.id] ?? false)) return player.treasury;
    }
    return 0;
  }

  /// Computes a short resources summary string for the HUD (grain, lumber, castIron).
  /// Format: g:<grain> L:<lumber> CI:<castIron>. Returns empty string when no resources.
  String inGameShellHudResourceSummary(Game? game) {
    if (game == null) return '';

    Player? human;
    for (final player in game.players) {
      final isAiControlled = game.aiControlByGpId[player.id] ?? false;
      if (!isAiControlled) {
        human = player;
        break;
      }
    }
    if (human == null) return '';

    final stockpile = human.stockpile;
    final grain = stockpile.quantityOf('grain');
    final lumber = stockpile.quantityOf('lumber');
    final castIron = stockpile.quantityOf('castIron');
    if (grain <= 0 && lumber <= 0 && castIron <= 0) {
      return '';
    }
    return 'g:$grain L:$lumber CI:$castIron';
  }

  String get _resourceSummary =>
      inGameShellHudResourceSummary(component.game);

  String get _regionDisplayName =>
      _selectedRegion == 'oldWorld' ? 'Old World' : 'New World';

  String? _humanPlayerId() {
    final game = component.game;
    if (game == null) return null;
    for (final entry in game.aiControlByGpId.entries) {
      if (!entry.value) return entry.key;
    }
    return null;
  }

  bool _isCivilianUnit(Unit unit) {
    final type = unit.type.toLowerCase();
    return type.contains('builder') || type.contains('engineer');
  }

  List<Unit> get _playerCivilianUnits {
    final game = component.game;
    final playerId = _humanPlayerId();
    if (game == null || playerId == null) return [];

    final units = <Unit>[];
    units.addAll(game.worldState.oldWorld.units
        .where((u) => u.ownerId == playerId && _isCivilianUnit(u)));
    units.addAll(game.worldState.newWorld.units
        .where((u) => u.ownerId == playerId && _isCivilianUnit(u)));
    return units;
  }

  int _idleCivilianCount() {
    final playerId = _humanPlayerId();
    if (playerId == null) return 0;
    final civs = _playerCivilianUnits;
    if (civs.isEmpty) return 0;

    final workOrders = _orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
    int idle = 0;
    for (final unit in civs) {
      final hasOrder =
          workOrders.any((order) => order.unitId == unit.id);
      if (!hasOrder) {
        idle++;
      }
    }
    return idle;
  }

  /// Land province node ids (local) in current region from topology. Empty if no topology.
  List<String> get _landProvinceLocalIds {
    final top = component.combinedTopology;
    if (top == null || top.nodes.isEmpty) return [];
    final provinceIds = top.nodes
        .where((n) =>
            n.regionId == _selectedRegion && n.type == TopologyNodeType.province)
        .map((n) => ProvinceId.localIdFrom(n.id))
        .toList();
    provinceIds.sort();
    return provinceIds;
  }

  /// Neighbours of [localId] in the land graph (P–P only).
  List<String> _neighboursOf(String localId) {
    final top = component.combinedTopology;
    if (top == null) return [];
    return neighborProvinceIdsInRegion(top, _selectedRegion, localId).toList();
  }

  /// Game provinces for current region.
  List<Province> get _provinces {
    final game = component.game;
    if (game == null) return [];
    return _selectedRegion == 'oldWorld'
        ? game.worldState.oldWorld.provinces
        : game.worldState.newWorld.provinces;
  }

  /// Find province by local id in current region (handles prefixed or local id in game).
  Province? _provinceByLocalId(String localId) {
    final fullId = ProvinceId.full(_selectedRegion, localId);
    for (final p in _provinces) {
      if (p.id == fullId || ProvinceId.localIdFrom(p.id) == localId) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _ensureSelection();
  }

  /// Returns the local id of the human player's capital in the current region, if any.
  String? _humanCapitalLocalIdInSelectedRegion() {
    final game = component.game;
    if (game == null) return null;

    for (final player in game.players) {
      final isAiControlled = game.aiControlByGpId[player.id] ?? false;
      if (isAiControlled || !player.isHuman) continue;
      final capitalId = player.capitalProvinceId;
      if (capitalId == null) continue;

      final capitalRegion = ProvinceId.regionIdFrom(capitalId);
      if (capitalRegion != _selectedRegion) continue;

      return ProvinceId.localIdFrom(capitalId);
    }

    return null;
  }

  void _ensureSelection() {
    final land = _landProvinceLocalIds;
    if (land.isEmpty) {
      if (_selectedProvinceLocalId != null) {
        setState(() => _selectedProvinceLocalId = null);
      }
      return;
    }

    // Prefer the human player's capital in this region when available; otherwise fall back to first province.
    final capitalLocalId = _humanCapitalLocalIdInSelectedRegion();
    final preferredId =
        (capitalLocalId != null && land.contains(capitalLocalId))
            ? capitalLocalId
            : land.first;

    if (_selectedProvinceLocalId == null ||
        !land.contains(_selectedProvinceLocalId)) {
      setState(() => _selectedProvinceLocalId = preferredId);
    }
  }

  void _cycleRegion() {
    setState(() {
      _selectedRegion =
          _selectedRegion == 'oldWorld' ? 'newWorld' : 'oldWorld';
      _selectedProvinceLocalId = null;
      _neighbourIndex = 0;
    });
    _ensureSelection();
    _log.d('tui:map: region changed to $_selectedRegion');
  }

  void _selectNextNeighbour() {
    final cur = _selectedProvinceLocalId;
    if (cur == null) return;
    final neighbours = _neighboursOf(cur);
    if (neighbours.isEmpty) return;
    final nextIdx = (_neighbourIndex + 1) % neighbours.length;
    final newId = neighbours[nextIdx];
    final newNeighbours = _neighboursOf(newId);
    final backIdx = newNeighbours.indexOf(cur);
    setState(() {
      _selectedProvinceLocalId = newId;
      _neighbourIndex = backIdx >= 0 ? backIdx : 0;
    });
  }

  void _selectPrevNeighbour() {
    final cur = _selectedProvinceLocalId;
    if (cur == null) return;
    final neighbours = _neighboursOf(cur);
    if (neighbours.isEmpty) return;
    final len = neighbours.length;
    final nextIdx = (_neighbourIndex - 1 + len) % len;
    final newId = neighbours[nextIdx];
    final newNeighbours = _neighboursOf(newId);
    final backIdx = newNeighbours.indexOf(cur);
    setState(() {
      _selectedProvinceLocalId = newId;
      _neighbourIndex = backIdx >= 0 ? backIdx : 0;
    });
  }

  /// Select neighbour at [index] (0-based) in the current province's neighbour list.
  void _selectNeighbourByIndex(int index) {
    final cur = _selectedProvinceLocalId;
    if (cur == null) return;
    if (index < 0) return;
    final neighbours = _neighboursOf(cur);
    if (index >= neighbours.length) return;
    final newId = neighbours[index];
    final newNeighbours = _neighboursOf(newId);
    final backIdx = newNeighbours.indexOf(cur);
    setState(() {
      _selectedProvinceLocalId = newId;
      _neighbourIndex = backIdx >= 0 ? backIdx : 0;
    });
  }

  /// Viewport (viewX, viewY) to center the map grid on the selected province when possible.
  /// Tile key format per SPEC/game/world-model-identity.md: regionId|localId|x|y.
  (int, int) _mapGridViewportFromSelectedProvince(
    TileMapResult tileMap,
    int viewportWidth,
    int viewportHeight,
  ) {
    final localId = _selectedProvinceLocalId;
    if (localId == null) return (0, 0);
    final game = component.game;
    if (game == null) return (0, 0);
    final fullProvinceId = '$_selectedRegion|$localId';
    final byProvince =
        game.worldState.tileKeysByRegionAndProvince[_selectedRegion];
    final tileKeys = byProvince?[fullProvinceId];
    if (tileKeys == null || tileKeys.isEmpty) return (0, 0);

    int sumX = 0;
    int sumY = 0;
    for (final key in tileKeys) {
      final parts = key.split('|');
      if (parts.length >= 4) {
        final x = int.tryParse(parts[2]) ?? 0;
        final y = int.tryParse(parts[3]) ?? 0;
        sumX += x;
        sumY += y;
      }
    }
    final count = tileKeys.length;
    if (count == 0) return (0, 0);
    final centerX = sumX ~/ count;
    final centerY = sumY ~/ count;
    final maxX = (tileMap.width - viewportWidth).clamp(0, tileMap.width);
    final maxY = (tileMap.height - viewportHeight).clamp(0, tileMap.height);
    final viewX = (centerX - viewportWidth ~/ 2).clamp(0, maxX);
    final viewY = (centerY - viewportHeight ~/ 2).clamp(0, maxY);
    return (viewX, viewY);
  }

  /// Builds a map of full tile key -> improvement level (> 0) for the
  /// currently selected region. Tiles with level 0 are omitted.
  Map<String, int> _improvementLevelsForSelectedRegion(Game game) {
    final worldState = game.worldState;
    final byRegion =
        worldState.tileKeysByRegionAndProvince[_selectedRegion];
    if (byRegion == null || byRegion.isEmpty) {
      return const {};
    }
    final tileState = worldState.tileState;
    final result = <String, int>{};
    for (final entry in byRegion.entries) {
      for (final key in entry.value) {
        final level = tileState.improvementLevel(key);
        if (level > 0) {
          result[key] = level;
        }
      }
    }
    return result;
  }

  Future<void> _handleEndTurn() async {
    if (_isEndingTurn) return;
    setState(() => _isEndingTurn = true);
    _log.d('tui:game: ending turn $_turn');
    await component.onEndTurn();
    final game = component.game;
    if (game?.victory != null) {
      final winnerId = game!.victory!.winnerPlayerId;
      final isHumanWinner =
          !(game.aiControlByGpId[winnerId] ?? false);
      setState(() => _isEndingTurn = false);
      if (isHumanWinner) {
        component.onVictory();
      } else {
        component.onDefeat();
      }
      return;
    }
    setState(() => _isEndingTurn = false);
  }

  @override
  Component build(BuildContext context) {
    _ensureSelection();
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final key = event.logicalKey;
        final c = event.character?.toLowerCase();

        if (_isConfirmingEndTurn) {
          if (key == LogicalKey.enter || c == 'y') {
            _log.d(
                'tui:game: end turn confirmed with $_idleCivilianCountForPrompt idle civilian unit(s)');
            setState(() {
              _isConfirmingEndTurn = false;
              _idleCivilianCountForPrompt = 0;
            });
            _handleEndTurn();
            return true;
          }
          if (key == LogicalKey.escape || c == 'n') {
            _log.d(
                'tui:game: end turn cancelled with $_idleCivilianCountForPrompt idle civilian unit(s)');
            setState(() {
              _isConfirmingEndTurn = false;
              _idleCivilianCountForPrompt = 0;
            });
            return true;
          }
          return false;
        }

        if (c == 'u') {
          component.onNavigate(CttermRoute.units);
          return true;
        }
        if (c == 'd') {
          component.onNavigate(CttermRoute.development);
          return true;
        }
        if (c == 'p') {
          component.onNavigate(CttermRoute.production);
          return true;
        }
        if (c == 'a') {
          component.onNavigate(CttermRoute.academy);
          return true;
        }
        if (c == 's') {
          component.onNavigate(CttermRoute.shipyard);
          return true;
        }
        if (c == 'i') {
          component.onNavigate(CttermRoute.diplomacy);
          return true;
        }
        if (c == 't') {
          component.onNavigate(CttermRoute.technology);
          return true;
        }
        if (c == 'v') {
          component.onNavigate(CttermRoute.victoryProgress);
          return true;
        }
        if (c == 'm') {
          _log.d('tui:nav: in-game shell -> map context');
          component.onNavigate(CttermRoute.mapContext);
          return true;
        }
        if (c == 'r') {
          _cycleRegion();
          return true;
        }
        // Map grid: [ / ] cycle layer (Terrain→Political→Resources→Units). Viewport centers on selected province. 1–9 = graph. SPEC/tui/screens/in-game-shell.md § Map Grid Widget.
        final tileMap = component.tileMapByRegion?[_selectedRegion];
        if (tileMap != null) {
          if (c == '[') {
            setState(() {
              switch (_mapGridLayer) {
                case MapGridLayer.terrain:
                  _mapGridLayer = MapGridLayer.units;
                  break;
                case MapGridLayer.political:
                  _mapGridLayer = MapGridLayer.terrain;
                  break;
                case MapGridLayer.resources:
                  _mapGridLayer = MapGridLayer.political;
                  break;
                case MapGridLayer.units:
                  _mapGridLayer = MapGridLayer.resources;
                  break;
              }
            });
            return true;
          }
          if (c == ']') {
            setState(() {
              switch (_mapGridLayer) {
                case MapGridLayer.terrain:
                  _mapGridLayer = MapGridLayer.political;
                  break;
                case MapGridLayer.political:
                  _mapGridLayer = MapGridLayer.resources;
                  break;
                case MapGridLayer.resources:
                  _mapGridLayer = MapGridLayer.units;
                  break;
                case MapGridLayer.units:
                  _mapGridLayer = MapGridLayer.terrain;
                  break;
              }
            });
            return true;
          }
        }
        // Graph navigation: next/prev neighbour (j/l, arrows). Direct selection 1–9.
        if (c == 'j' || key == LogicalKey.arrowLeft) {
          _selectPrevNeighbour();
          return true;
        }
        if (c == 'l' || key == LogicalKey.arrowRight) {
          _selectNextNeighbour();
          return true;
        }
        // Direct neighbour selection via number keys 1–9 (indices 0–8). Map layers use t/p/r/u.
        if (c != null && c.length == 1 && c.codeUnitAt(0) >= '1'.codeUnitAt(0) &&
            c.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
          final index = c.codeUnitAt(0) - '1'.codeUnitAt(0);
          _selectNeighbourByIndex(index);
          return true;
        }
        if (c == 'e' || key == LogicalKey.enter) {
          final idleCount = _idleCivilianCount();
          if (idleCount > 0) {
            setState(() {
              _isConfirmingEndTurn = true;
              _idleCivilianCountForPrompt = idleCount;
            });
            return true;
          }
          _handleEndTurn();
          return true;
        }
        if (c == 'o' || c == 'x' || key == LogicalKey.escape) {
          component.onNavigate(CttermRoute.pauseOptions);
          return true;
        }
        return false;
      },
      child: Column(
        children: [
          _buildHUD(),
          const SizedBox(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildMapArea()),
                Expanded(flex: 2, child: _buildProvinceInfoPanel()),
              ],
            ),
          ),
          _buildEventsBar(),
          _buildCommandBar(),
        ],
      ),
    );
  }

  Component _buildHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Turn: $_turn | Year: $_year | Treasury: \$$_treasury | '
              'Res: ${_resourceSummary.isEmpty ? "-" : _resourceSummary} | '
              'Region: $_regionDisplayName [R]'),
        ],
      ),
    );
  }

  Component _buildMapArea() {
    final top = component.combinedTopology;
    final land = _landProvinceLocalIds;
    final tileMap = component.tileMapByRegion?[_selectedRegion];
    const viewportWidth = 24;
    const viewportHeight = 8;

    final topologySection = (top == null || top.nodes.isEmpty || land.isEmpty)
        ? Container(
            padding: const EdgeInsets.all(1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No topology', style: TextStyle(color: Colors.gray)),
                Text('Provinces in region: ${_provinces.length}',
                    style: TextStyle(color: Colors.gray)),
              ],
            ),
          )
        : _buildTopologyContent();

    final game = component.game;
    if (tileMap == null || game == null) {
      return Container(
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('=== $_regionDisplayName (land graph) ===',
                style: TextStyle(color: Colors.cyan)),
            topologySection,
          ],
        ),
      );
    }

    final (viewX, viewY) = _mapGridViewportFromSelectedProvince(
      tileMap,
      viewportWidth,
      viewportHeight,
    );

    final improvementLevels = _improvementLevelsForSelectedRegion(game);

    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MapGridWidget(
            regionId: _selectedRegion,
            tileMap: tileMap,
            game: game,
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight,
            viewX: viewX,
            viewY: viewY,
            layer: _mapGridLayer,
            improvementLevelByTileKey: improvementLevels,
          ),
          const SizedBox(height: 1),
          Text('=== $_regionDisplayName (land graph) ===',
              style: TextStyle(color: Colors.cyan)),
          Text(
              'Center = current province; 1–9: neighbour, j/l or arrows: cycle',
              style: TextStyle(color: Colors.gray)),
          const SizedBox(height: 1),
          Expanded(child: topologySection),
        ],
      ),
    );
  }

  Component _buildTopologyContent() {
    final selected = _selectedProvinceLocalId;
    final selectedProv =
        selected != null ? _provinceByLocalId(selected) : null;
    final neighbours =
        selected != null ? _neighboursOf(selected) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected == null || selectedProv == null)
          Text('No province selected', style: TextStyle(color: Colors.gray))
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _provinceLabel(selectedProv, selected),
                style: TextStyle(
                  color: _provinceTextColor(selectedProv),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text('->', style: TextStyle(color: Colors.gray)),
              const SizedBox(width: 1),
              if (neighbours.isEmpty)
                Text('No neighbours', style: TextStyle(color: Colors.gray))
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < neighbours.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Text(
                            _neighbourLabel(neighbours[i], i),
                            style: TextStyle(
                              color: _provinceTextColor(
                                _provinceByLocalId(neighbours[i]),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Component _buildProvinceInfoPanel() {
    final prov = _selectedProvinceLocalId != null
        ? _provinceByLocalId(_selectedProvinceLocalId!)
        : null;
    final game = component.game;
    final isSeabound = _selectedProvinceLocalId != null &&
        _isProvinceSeaBound(_selectedProvinceLocalId!);

    int improvedTiles = 0;
    if (prov != null && game != null) {
      final worldState = game.worldState;
      final byRegion =
          worldState.tileKeysByRegionAndProvince[_selectedRegion];
      final tiles = byRegion?[prov.id];
      if (tiles != null) {
        final tileState = worldState.tileState;
        for (final key in tiles) {
          if (tileState.improvementLevel(key) > 0) {
            improvedTiles++;
          }
        }
      }
    }

    String ownerName(String? ownerId) {
      if (ownerId == null) return 'Unclaimed';
      if (game == null) return ownerId;
      for (final p in game.players) {
        if (p.id == ownerId) return p.displayName;
      }
      return ownerId;
    }

    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Province Info',
              style: TextStyle(
                  color: Colors.cyan, fontWeight: FontWeight.bold)),
          const SizedBox(height: 1),
          if (prov == null)
            Text('No province selected', style: TextStyle(color: Colors.gray))
          else ...[
            Text('Name: ${prov.displayName ?? prov.id}',
                style: TextStyle(color: Colors.yellow)),
            Text('Owner: ${ownerName(prov.ownerId)}'),
            Text('Terrain: ${prov.terrain}'),
            Text('Fort: ${prov.fortLevel}'),
            Text('Town Dev: ${prov.townDevelopmentLevel}'),
            Text('Seabound: ${isSeabound ? "Yes" : "No"}'),
            Text('Improved tiles: $improvedTiles'),
            Text('Visibility: full', style: TextStyle(color: Colors.gray)),
          ],
          const Spacer(),
          Text('1–9: neighbour, j/l or arrows: cycle',
              style: TextStyle(color: Colors.gray)),
        ],
      ),
    );
  }

  /// Returns true when the province with [localId] in the current region has at
  /// least one P–S edge (sea-bound) in the combined topology.
  bool _isProvinceSeaBound(String localId) {
    final top = component.combinedTopology;
    if (top == null || top.nodes.isEmpty) return false;
    final regionId = _selectedRegion;

    final provinceNodeIds = top.nodes
        .where((n) =>
            n.regionId == regionId &&
            n.type == TopologyNodeType.province &&
            ProvinceId.localIdFrom(n.id) == localId)
        .map((n) => n.id)
        .toSet();
    if (provinceNodeIds.isEmpty) return false;

    final seaNodeIds = top.nodes
        .where((n) =>
            n.regionId == regionId && n.type == TopologyNodeType.seaZone)
        .map((n) => n.id)
        .toSet();
    if (seaNodeIds.isEmpty) return false;

    for (final edge in top.edges) {
      final id1 = edge.id1;
      final id2 = edge.id2;
      String? provinceSide;
      if (provinceNodeIds.contains(id1)) {
        provinceSide = id1;
      } else if (provinceNodeIds.contains(id2)) {
        provinceSide = id2;
      }
      if (provinceSide == null) continue;
      final other = provinceSide == id1 ? id2 : id1;
      if (seaNodeIds.contains(other)) {
        return true;
      }
    }
    return false;
  }

  /// Province label for the centered view, including seabound marker.
  String _provinceLabel(Province? prov, String localId) {
    final base = prov?.displayName ?? prov?.id ?? localId;
    final seabound = _isProvinceSeaBound(localId);
    return seabound ? '$base*' : base;
  }

  /// Label for neighbour [localId] at [index] (0-based), including hotkey index and seabound marker.
  String _neighbourLabel(String localId, int index) {
    final prov = _provinceByLocalId(localId);
    final name = _provinceLabel(prov, localId);
    final keyIndex = index + 1;
    final keyPart = keyIndex <= 9 ? '$keyIndex' : '-';
    return '$keyPart:$name';
  }

  /// Text colour for a province based on owning Great Power colour override (when present).
  Color _provinceTextColor(Province? prov) {
    if (prov == null) return Colors.gray;
    final ownerId = prov.ownerId;
    final game = component.game;
    if (ownerId == null || game == null) return Colors.gray;
    final override = game.greatPowerColorOverride;
    final rgb = override?[ownerId];
    if (rgb == null || rgb.length < 3) return Colors.gray;
    final r = rgb[0];
    final g = rgb[1];
    final b = rgb[2];

    if (r == g && g == b) {
      return r > 200 ? Colors.white : Colors.gray;
    }
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    if (max == r && max == g) return Colors.yellow;
    if (max == r && max == b) return Colors.magenta;
    if (max == g && max == b) return Colors.cyan;
    if (max == r) return Colors.red;
    if (max == g) return Colors.green;
    if (max == b) return Colors.blue;
    return Colors.gray;
  }

  String _provinceNameFromId(String fullProvinceId) {
    final game = component.game;
    if (game == null) return fullProvinceId;
    for (final p in game.worldState.oldWorld.provinces) {
      if (p.id == fullProvinceId) return p.displayName ?? p.id;
    }
    for (final p in game.worldState.newWorld.provinces) {
      if (p.id == fullProvinceId) return p.displayName ?? p.id;
    }
    return fullProvinceId;
  }

  String _formatEvent(GameEvent event) {
    if (event is CombatResultEvent) {
      return 'Battle: ${event.winnerId} wins';
    } else if (event is ProvinceCapturedEvent) {
      final name = _provinceNameFromId(event.provinceId);
      return 'Captured: $name by ${event.newOwnerId}';
    } else if (event is ResearchCompleteEvent) {
      return 'Research: ${event.techId}';
    } else if (event is VictorySetEvent) {
      return 'Victory: ${event.winnerPlayerId}';
    }
    return event.toString();
  }

  Component _buildEventsBar() {
    final events = component.gameEvents;
    if (events == null || events.isEmpty) return const SizedBox.shrink();
    final recent =
        events.length > 3 ? events.sublist(events.length - 3) : events;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('--- Events ---', style: TextStyle(color: Colors.gray)),
          ...recent.map((e) =>
              Text(_formatEvent(e), style: TextStyle(color: Colors.yellow))),
        ],
      ),
    );
  }

  Component _buildCommandBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: _isEndingTurn
          ? Text('Processing turn...', style: TextStyle(color: Colors.yellow))
          : _isConfirmingEndTurn
              ? Text(
                  '$_idleCivilianCountForPrompt civilian unit(s) are idle. End turn anyway? [Y]es [N]o',
                  style: TextStyle(color: Colors.yellow),
                )
              : Row(
                  children: [
                    const Text('['),
                    Text('M', style: TextStyle(color: Colors.cyan)),
                    const Text(']ap ['),
                    Text('R', style: TextStyle(color: Colors.cyan)),
                    const Text(']egion '),
                    const Text('['),
                    Text('U', style: TextStyle(color: Colors.cyan)),
                    const Text(']nits ['),
                    Text('D', style: TextStyle(color: Colors.cyan)),
                    const Text(']ev ['),
                    Text('P', style: TextStyle(color: Colors.cyan)),
                    const Text(']rod ['),
                    Text('A', style: TextStyle(color: Colors.cyan)),
                    const Text(']cademy ['),
                    Text('S', style: TextStyle(color: Colors.cyan)),
                    const Text(']hipyard ['),
                    Text('E', style: TextStyle(color: Colors.cyan)),
                    const Text(']nd* ['),
                    Text('O', style: TextStyle(color: Colors.cyan)),
                    const Text(']ptions  (*prompts if idle civilians)'),
                  ],
                ),
    );
  }
}
