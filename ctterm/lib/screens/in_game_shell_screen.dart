// In-Game Shell: topology graph map + HUD + province info + panel navigation.
// SPEC/tui/ctterm.md, SPEC/tui/screens/in-game-shell.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// In-game shell: topology graph map, HUD, province info panel, navigation to panels.
class InGameShellScreen extends StatefulComponent {
  const InGameShellScreen({
    super.key,
    this.game,
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

  int get _turn => component.game?.worldState.turnState.turnNumber ?? 1;
  int get _year => 1850 + ((_turn - 1) * 5);

  int get _treasury {
    final game = component.game;
    if (game == null) return 0;
    for (final player in game.players) {
      if (!(game.aiControlByGpId[player.id] ?? false)) return player.treasury;
    }
    return 0;
  }

  String get _regionDisplayName =>
      _selectedRegion == 'oldWorld' ? 'Old World' : 'New World';

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
        // Graph navigation: next/prev neighbour (j/k or left/right)
        if (c == 'j' || key == LogicalKey.arrowLeft) {
          _selectPrevNeighbour();
          return true;
        }
        if (c == 'l' || key == LogicalKey.arrowRight) {
          _selectNextNeighbour();
          return true;
        }
        if (c == 'e' || key == LogicalKey.enter) {
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
              'Turn: $_turn | Year: $_year | Treasury: \$$_treasury | Region: $_regionDisplayName [R]'),
        ],
      ),
    );
  }

  Component _buildMapArea() {
    final top = component.combinedTopology;
    final land = _landProvinceLocalIds;
    if (top == null || top.nodes.isEmpty || land.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No topology', style: TextStyle(color: Colors.gray)),
            Text('Provinces in region: ${_provinces.length}',
                style: TextStyle(color: Colors.gray)),
          ],
        ),
      );
    }

    const cols = 5;
    final rows = (land.length / cols).ceil();
    final selected = _selectedProvinceLocalId;
    final neighbours = selected != null ? _neighboursOf(selected) : <String>[];

    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('=== $_regionDisplayName (land graph) ===',
              style: TextStyle(color: Colors.cyan)),
          Text('Select: j/l or ←/→ move to neighbour',
              style: TextStyle(color: Colors.gray)),
          const SizedBox(height: 1),
          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(cols, (col) {
                final idx = row * cols + col;
                if (idx >= land.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                    child: Text('   '),
                  );
                }
                final localId = land[idx];
                final prov = _provinceByLocalId(localId);
                final name = prov?.displayName ?? prov?.id ?? localId;
                final short = name.length > 6 ? name.substring(0, 6) : name;
                final isSelected = localId == selected;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
                  child: Text(
                    isSelected ? '[$short]' : ' $short ',
                    style: isSelected
                        ? TextStyle(
                            backgroundColor: Colors.cyan,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          )
                        : TextStyle(color: Colors.gray),
                  ),
                );
              }),
            );
          }),
          const SizedBox(height: 1),
          if (selected != null && neighbours.isNotEmpty)
            Text(
              'Neighbours: ${neighbours.map((n) => _provinceByLocalId(n)?.displayName ?? n).join(", ")}',
              style: TextStyle(color: Colors.yellow),
            ),
        ],
      ),
    );
  }

  Component _buildProvinceInfoPanel() {
    final prov = _selectedProvinceLocalId != null
        ? _provinceByLocalId(_selectedProvinceLocalId!)
        : null;
    final game = component.game;

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
            Text(
                'ID: ${ProvinceId.isPrefixed(prov.id) ? prov.id : ProvinceId.full(_selectedRegion, prov.id)}',
                style: TextStyle(color: Colors.yellow)),
            Text('Name: ${prov.displayName ?? prov.id}'),
            Text('Owner: ${ownerName(prov.ownerId)}'),
            Text('Terrain: ${prov.terrain}'),
            Text('Fort: ${prov.fortLevel}'),
            Text('Town Dev: ${prov.townDevelopmentLevel}'),
            Text('Visibility: full', style: TextStyle(color: Colors.gray)),
          ],
          const Spacer(),
          Text('j/l or ←/→: neighbour', style: TextStyle(color: Colors.gray)),
        ],
      ),
    );
  }

  String _formatEvent(GameEvent event) {
    if (event is CombatResultEvent) {
      return 'Battle: ${event.winnerId} wins';
    } else if (event is ProvinceCapturedEvent) {
      return 'Captured: ${event.provinceId} by ${event.newOwnerId}';
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
                const Text(']nd ['),
                Text('O', style: TextStyle(color: Colors.cyan)),
                const Text(']ptions'),
              ],
            ),
    );
  }
}
