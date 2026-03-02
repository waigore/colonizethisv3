// In-Game Shell: map + HUD + panel navigation. SPEC/tui/ctterm.md, SPEC/tui/screens/in-game-shell.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/map_tui_mapping.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// In-game shell: main game view with ASCII map, HUD, and navigation to panels.
/// 
/// Features:
/// - ASCII map display (from real game data)
/// - HUD with turn/year, treasury
/// - Keyboard navigation to panels (U, D, P, A, S, I, T, V)
/// - Map context (M)
/// - End turn (E or Enter)
/// - Pause/Options (O or Escape)
class InGameShellScreen extends StatefulComponent {
  const InGameShellScreen({
    super.key,
    this.game,
    this.gameEvents,
    this.tileMapByRegion,
    required this.onNavigate,
    required this.onEndTurn,
    required this.onVictory,
    required this.onDefeat,
    required this.onExitToMainMenu,
  });

  /// Current game state for victory checking.
  final Game? game;
  /// Game events from turn processing (to display to user).
  final List<GameEvent>? gameEvents;
  /// Tile maps by region (oldWorld, newWorld) for map rendering.
  final Map<String, TileMapResult>? tileMapByRegion;
  final void Function(CttermRoute) onNavigate;
  final Future<void> Function() onEndTurn;
  /// Callback when human player wins.
  final void Function() onVictory;
  /// Callback when AI player wins (human defeated).
  final void Function() onDefeat;
  final void Function() onExitToMainMenu;

  @override
  State<InGameShellScreen> createState() => _InGameShellScreenState();
}

class _InGameShellScreenState extends State<InGameShellScreen> {
  // Selected region for map display: 'oldWorld' or 'newWorld'
  String _selectedRegion = 'oldWorld';
  bool _isEndingTurn = false;

  /// Gets the current turn number from game state.
  int get _turn => component.game?.worldState.turnState.turnNumber ?? 1;
  
  /// Gets the current year from game state.
  int get _year => 1850 + ((_turn - 1) * 5);
  
  /// Gets the human player's treasury from game state.
  int get _treasury {
    final game = component.game;
    if (game == null) return 0;
    // Find human player (non-AI controlled)
    for (final player in game.players) {
      final isAi = game.aiControlByGpId[player.id] ?? false;
      if (!isAi) {
        return player.treasury;
      }
    }
    return 0;
  }

  /// Gets provinces for the currently selected region.
  List<Province> get _provinces {
    final game = component.game;
    if (game == null) return [];
    
    if (_selectedRegion == 'oldWorld') {
      return game.worldState.oldWorld.provinces;
    } else {
      return game.worldState.newWorld.provinces;
    }
  }

  /// Gets the region display name.
  String get _regionDisplayName => _selectedRegion == 'oldWorld' ? 'Old World' : 'New World';

  /// Gets a short code for the player (first letter of ID, uppercased).
  String _getPlayerCode(String? playerId) {
    if (playerId == null) return '?';
    return playerId.substring(0, 1).toUpperCase();
  }

  /// Gets the current tile map for the selected region.
  TileMapResult? get _tileMap {
    final tileMaps = component.tileMapByRegion;
    if (tileMaps == null) return null;
    
    final regionKey = _selectedRegion == 'oldWorld' ? 'ow' : 'nw';
    return tileMaps[regionKey];
  }

  /// Gets the human player's visibility map.
  Map<String, String>? get _playerVisibility {
    final game = component.game;
    if (game == null) return null;
    
    // Find human player
    String? humanId;
    for (final player in game.players) {
      final isAi = game.aiControlByGpId[player.id] ?? false;
      if (!isAi) {
        humanId = player.id;
        break;
      }
    }
    
    if (humanId == null) return null;
    return game.worldState.playerVisibilityByTile[humanId];
  }

  /// Builds ASCII map from tile data using TUI mapping.
  List<String> get _mapGrid {
    final game = component.game;
    final tileMap = _tileMap;
    
    // Fallback to old province grid if no tile map
    if (game == null || tileMap == null) {
      return _buildProvinceGrid();
    }
    
    // Get provinces for the region
    final provinces = _provinces;
    final provincesById = buildProvincesMap(provinces);
    
    // Get player list
    final players = game.players;
    
    // Get capital and port tiles
    final capitalTiles = getCapitalTiles(game);
    final portTiles = getPortTiles(game.worldState);
    
    // Get player visibility
    final visibility = _playerVisibility;
    
    // Limit map size for display (terminal constraints)
    const maxMapWidth = 40;
    const maxMapHeight = 15;
    
    // Render the map using the TUI mapping
    final lines = <String>[];
    
    // Header with region name
    lines.add('=== $_regionDisplayName ===');
    
    // Render tile map
    final mapLines = renderRegionMap(
      tileMap: tileMap,
      provincesById: provincesById,
      playerVisibilityByTile: visibility,
      players: players,
      capitalTiles: capitalTiles,
      portTiles: portTiles,
      showTerrain: true,
      showOwnership: true,
      maxWidth: maxMapWidth,
      maxHeight: maxMapHeight,
    );
    
    lines.addAll(mapLines);
    
    return lines;
  }

  /// Fallback: builds ASCII map from province data (when no tile map available).
  List<String> _buildProvinceGrid() {
    final provinces = _provinces;
    if (provinces.isEmpty) {
      return ['[No map data available]'];
    }
    
    // Group provinces by a simple grid layout
    // For MVP, show provinces in a simple grid format
    final lines = <String>[];
    
    // Header
    lines.add('=== $_regionDisplayName ===');
    lines.add('');
    
    // Province grid - organize into columns
    const cols = 4;
    final rows = (provinces.length / cols).ceil();
    
    for (var row = 0; row < rows; row++) {
      final rowProvs = <String>[];
      for (var col = 0; col < cols; col++) {
        final idx = row * cols + col;
        if (idx < provinces.length) {
          final prov = provinces[idx];
          final ownerCode = _getPlayerCode(prov.ownerId);
          final name = prov.displayName ?? prov.id;
          // Truncate name to fit
          final shortName = name.length > 8 ? name.substring(0, 8) : name;
          rowProvs.add('[$ownerCode$shortName]');
        } else {
          rowProvs.add('           ');
        }
      }
      lines.add(rowProvs.join(' '));
    }
    
    return lines;
  }

  /// Gets legend text showing owner codes.
  String get _legend {
    final game = component.game;
    if (game == null) return '';
    
    final parts = <String>[];
    for (final player in game.players) {
      final code = _getPlayerCode(player.id);
      parts.add('$code=${player.displayName}');
    }
    parts.add('?=Unclaimed');
    return parts.join(' | ');
  }

  Future<void> _handleEndTurn() async {
    if (_isEndingTurn) return;
    setState(() => _isEndingTurn = true);
    _log.d('tui:game: ending turn $_turn');
    
    await component.onEndTurn();
    
    // Check for victory/defeat after turn processing
    final game = component.game;
    if (game?.victory != null) {
      final winnerId = game!.victory!.winnerPlayerId;
      final isHumanWinner = _isHumanPlayer(winnerId, game);
      _log.i('tui:game: victory detected winner=$winnerId isHuman=$isHumanWinner');
      setState(() => _isEndingTurn = false);
      if (isHumanWinner) {
        component.onVictory();
      } else {
        component.onDefeat();
      }
      return;
    }
    
    setState(() => _isEndingTurn = false);
    _log.d('tui:game: now turn $_turn, year $_year');
  }

  /// Checks if the given playerId is the human player.
  bool _isHumanPlayer(String playerId, Game game) {
    // Human player is one where aiControlByGpId is false or not set
    return !(game.aiControlByGpId[playerId] ?? false);
  }

  /// Cycles between Old World and New World regions.
  void _cycleRegion() {
    setState(() {
      _selectedRegion = _selectedRegion == 'oldWorld' ? 'newWorld' : 'oldWorld';
    });
    _log.d('tui:map: region changed to $_selectedRegion');
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final key = event.logicalKey;
        final c = event.character?.toLowerCase();
        
        // Navigation keys
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
        
        // Map context (M key)
        if (c == 'm') {
          _log.d('tui:nav: in-game shell -> map context');
          component.onNavigate(CttermRoute.mapContext);
          return true;
        }
        
        // Region cycle (R key)
        if (c == 'r') {
          _cycleRegion();
          return true;
        }
        
        // End turn
        if (c == 'e' || key == LogicalKey.enter) {
          _handleEndTurn();
          return true;
        }
        
        // Pause/Options (Escape, O, or P per SPEC/tui/screens/pause-options.md)
        if (c == 'o' || c == 'p' || key == LogicalKey.escape) {
          component.onNavigate(CttermRoute.pauseOptions);
          return true;
        }
        
        return false;
      },
      child: Column(
        children: [
          // HUD
          _buildHUD(),
          const SizedBox(height: 1),
          // Map
          Expanded(child: _buildMap()),
          // Events bar (shows recent game events)
          _buildEventsBar(),
          // Command bar
          _buildCommandBar(),
        ],
      ),
    );
  }

  /// HUD per SPEC/tui/screens/in-game-shell.md § G2 and UI Layout: turn, year, treasury, selected province.
  Component _buildHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Turn: $_turn | Year: $_year | Treasury: \$$_treasury | [Selected: None]'),
          Text('Region: [$_regionDisplayName] (Press R to cycle)', style: TextStyle(color: Colors.gray)),
        ],
      ),
    );
  }

  Component _buildMap() {
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ..._mapGrid.map((row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Text(row),
          )),
          const SizedBox(height: 1),
          Text('Legend: $_legend', style: TextStyle(color: Colors.gray)),
        ],
      ),
    );
  }

  /// Formats a game event for display.
  String _formatEvent(GameEvent event) {
    if (event is CombatResultEvent) {
      return 'Battle in ${event.provinceId}: ${event.winnerId} wins';
    } else if (event is ProvinceCapturedEvent) {
      return 'Province captured: ${event.provinceId} by ${event.newOwnerId}';
    } else if (event is DiplomacyChangeEvent) {
      return 'Diplomacy: ${event.actorId} -> ${event.targetId}: ${event.changeType}';
    } else if (event is ResearchCompleteEvent) {
      return 'Research: ${event.playerId} discovered ${event.techId}';
    } else if (event is VictorySetEvent) {
      return 'Victory: ${event.winnerPlayerId} wins (${event.victoryType})';
    } else if (event is OrderRejectedEvent) {
      return 'Order rejected: ${event.orderSummary} (${event.reasonCode})';
    }
    return event.toString();
  }

  /// Builds the events display (shows recent game events).
  Component _buildEventsBar() {
    final events = component.gameEvents;
    if (events == null || events.isEmpty) {
      return const SizedBox.shrink();
    }
    // Show last 3 events
    final recentEvents = events.length > 3 ? events.sublist(events.length - 3) : events;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('--- Events ---', style: TextStyle(color: Colors.gray)),
          ...recentEvents.map((e) => Text(_formatEvent(e), style: TextStyle(color: Colors.yellow))),
        ],
      ),
    );
  }

  /// Command bar per SPEC/tui/screens/in-game-shell.md UI Layout (G3, G4, G5).
  Component _buildCommandBar() {
    if (_isEndingTurn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Text('Processing turn...', style: TextStyle(color: Colors.yellow)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Commands: '),
              _cmdKey('U'), const Text('nits '),
              _cmdKey('D'), const Text('ev '),
              _cmdKey('P'), const Text('rod '),
              _cmdKey('A'), const Text('cademy '),
              _cmdKey('S'), const Text('hipyard '),
            ],
          ),
          Row(
            children: [
              _cmdKey('I'), const Text('ntl '),
              _cmdKey('T'), const Text('ech '),
              _cmdKey('V'), const Text('ictory '),
              _cmdKey('E'), const Text('nd Turn '),
              _cmdKey('O'), const Text('ptions '),
            ],
          ),
        ],
      ),
    );
  }

  static Component _cmdKey(String key) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('[$key]', style: TextStyle(color: Colors.cyan)),
    ],
  );
}
