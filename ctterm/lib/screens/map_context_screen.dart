// Map Context Screen: detailed province information, map layers, visibility, region navigation.
// SPEC/tui/ctterm.md, SPEC/tui/screens/map-context.md

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Map context screen showing detailed province information, map layers, and region navigation.
class MapContextScreen extends StatefulComponent {
  const MapContextScreen({
    super.key,
    required this.game,
    required this.onNavigate,
  });

  final Game game;
  final void Function(CttermRoute) onNavigate;

  @override
  State<MapContextScreen> createState() => _MapContextScreenState();
}

class _MapContextScreenState extends State<MapContextScreen> {
  // Current region (oldWorld or newWorld)
  String _currentRegion = 'oldWorld';
  static const List<String> _regions = ['oldWorld', 'newWorld'];

  // Map layers (toggleable)
  bool _showTerrain = true;
  bool _showOwnership = true;
  bool _showTowns = true;
  bool _showFog = true;

  // Selection state
  int _cursorX = 0;
  int _cursorY = 0;
  bool _tileMode = false; // false = province, true = tile

  /// Gets the game from the widget.
  Game get game => component.game;

  /// Gets the current region's display name.
  String get _regionDisplayName => _currentRegion == 'oldWorld' ? 'Old World' : 'New World';

  /// Gets the region ID prefix for the current region (oldWorld -> 'ow', newWorld -> 'nw').
  String get _regionId {
    return _currentRegion == 'oldWorld' ? 'ow' : 'nw';
  }

  /// Gets the human player's ID (first player with isHuman == true).
  String? get _humanPlayerId {
    final human = game.players.where((p) => p.isHuman).firstOrNull;
    return human?.id;
  }

  /// Checks if a province is at least revealed to the human player.
  /// Uses WorldState.playerVisibilityByTile directly.
  bool _provinceIsVisible(Province province) {
    final playerId = _humanPlayerId;
    if (playerId == null) return false;

    final visibilityByTile = game.worldState.playerVisibilityByTile[playerId];
    if (visibilityByTile == null) return false;

    // Get the tile keys for this province from WorldState
    final tileKeysByProv = game.worldState.tileKeysByRegionAndProvince;
    final regionTileKeys = tileKeysByProv[_regionId];
    if (regionTileKeys == null) return false;

    final provTileKeys = regionTileKeys[province.id];
    if (provTileKeys == null || provTileKeys.isEmpty) return false;

    // Check if any tile in the province is at least revealed
    for (final tileKey in provTileKeys) {
      final levelName = visibilityByTile[tileKey];
      if (levelName == 'revealed' || levelName == 'fogged' || levelName == 'fullyVisible') {
        return true;
      }
    }
    return false;
  }

  /// Gets provinces for the currently selected region.
  List<Province> get _provinces {
    if (_currentRegion == 'oldWorld') {
      return game.worldState.oldWorld.provinces;
    } else {
      return game.worldState.newWorld.provinces;
    }
  }

  /// Gets the currently selected province based on cursor position.
  Province? get _selectedProvince {
    final provinces = _provinces;
    final idx = _cursorY * 4 + _cursorX;
    if (idx >= 0 && idx < provinces.length) {
      return provinces[idx];
    }
    return null;
  }

  void _cycleRegion() {
    setState(() {
      final idx = _regions.indexOf(_currentRegion);
      _currentRegion = _regions[(idx + 1) % _regions.length];
    });
    _log.d('tui:map: region changed to $_currentRegion');
  }

  void _toggleLayer(int layer) {
    setState(() {
      switch (layer) {
        case 1:
          _showTerrain = !_showTerrain;
          break;
        case 2:
          _showOwnership = !_showOwnership;
          break;
        case 3:
          _showTowns = !_showTowns;
          break;
        case 4:
          _showFog = !_showFog;
          break;
      }
    });
    _log.d('tui:map: layer toggled: terrain=$_showTerrain ownership=$_showOwnership towns=$_showTowns fog=$_showFog');
  }

  void _moveCursor(int dx, int dy) {
    final provinces = _provinces;
    const cols = 4;
    final rows = provinces.isEmpty ? 0 : (provinces.length / cols).ceil();
    setState(() {
      final newX = (_cursorX + dx).clamp(0, cols - 1);
      final newY = (_cursorY + dy).clamp(0, rows - 1);
      _cursorX = newX;
      _cursorY = newY;
    });
  }

  void _cycleSelection() {
    setState(() {
      _tileMode = !_tileMode;
    });
    _log.d('tui:map: selection mode: ${_tileMode ? "tile" : "province"}');
  }

  /// Gets the currently selected province data.
  Province? get _currentProvince => _selectedProvince;

  String _getVisibilityIcon(_Visibility visibility) {
    switch (visibility) {
      case _Visibility.full:
        return '●';
      case _Visibility.revealed:
        return '○';
      case _Visibility.fog:
        return '?';
    }
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final key = event.logicalKey;
        final c = event.character?.toLowerCase();

        // Region cycling
        if (c == 'r') {
          _cycleRegion();
          return true;
        }

        // Layer toggles (1-4)
        if (c == '1') {
          _toggleLayer(1);
          return true;
        }
        if (c == '2') {
          _toggleLayer(2);
          return true;
        }
        if (c == '3') {
          _toggleLayer(3);
          return true;
        }
        if (c == '4') {
          _toggleLayer(4);
          return true;
        }

        // Selection mode cycling (Tab, w, s)
        if (key == LogicalKey.tab || c == 'w' || c == 's') {
          _cycleSelection();
          return true;
        }

        // Map navigation - arrow keys or h/j/k/l
        if (key == LogicalKey.arrowUp || c == 'k') {
          _moveCursor(0, -1);
          return true;
        }
        if (key == LogicalKey.arrowDown || c == 'j') {
          _moveCursor(0, 1);
          return true;
        }
        if (key == LogicalKey.arrowLeft || c == 'h') {
          _moveCursor(-1, 0);
          return true;
        }
        if (key == LogicalKey.arrowRight || c == 'l') {
          _moveCursor(1, 0);
          return true;
        }

        // Escape - go back
        if (key == LogicalKey.escape) {
          _log.d('tui:nav: map context -> in-game shell');
          component.onNavigate(CttermRoute.inGameShell);
          return true;
        }

        return false;
      },
      child: Row(
        children: [
          // Map panel (left)
          Expanded(flex: 3, child: _buildMapPanel()),
          // Context panel (right)
          Expanded(flex: 2, child: _buildContextPanel()),
        ],
      ),
    );
  }

  Component _buildMapPanel() {
    final provinces = _provinces;
    if (provinces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(1),
        child: Text('No map data available', style: TextStyle(color: Colors.gray)),
      );
    }

    // Build map grid from real province data
    const cols = 4;
    final rows = (provinces.length / cols).ceil();

    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region indicator
          Text('Region: $_regionDisplayName', style: TextStyle(color: Colors.cyan)),
          const SizedBox(height: 1),
          // Map grid
          ...List.generate(rows, (y) {
            return Row(
              children: List.generate(cols, (x) {
                final idx = y * cols + x;
                final isSelected = x == _cursorX && y == _cursorY;
                
                String cellChar;
                var style = TextStyle();
                
                if (idx < provinces.length) {
                  final prov = provinces[idx];
                  final name = prov.displayName ?? prov.id;
                  // Shorten to 2 chars for the grid cell
                  cellChar = name.length > 2 ? name.substring(0, 2) : name;
                } else {
                  cellChar = '  ';
                }
                
                if (isSelected) {
                  style = TextStyle(backgroundColor: Colors.cyan, color: Colors.black);
                  cellChar = '[$cellChar]';
                } else {
                  cellChar = ' $cellChar ';
                }

                // Apply ownership coloring
                if (idx < provinces.length) {
                  final prov = provinces[idx];
                  if (_showOwnership && prov.ownerId != null) {
                    // Color by player ID prefix (simplified)
                    final pid = prov.ownerId!.toLowerCase();
                    if (pid.startsWith('gb') || pid.startsWith('britain')) {
                      style = style.copyWith(color: Colors.red);
                    } else if (pid.startsWith('fr')) {
                      style = style.copyWith(color: Colors.blue);
                    } else if (pid.startsWith('sp')) {
                      style = style.copyWith(color: Colors.yellow);
                    } else {
                      style = style.copyWith(color: Colors.green);
                    }
                  }
                  if (_showFog) {
                    // Use real visibility from PlayerView
                    final isVisible = _provinceIsVisible(prov);
                    if (!isVisible) {
                      // Province is hidden or in fog - show as gray
                      style = style.copyWith(color: Colors.gray);
                    }
                  }
                }

                return Text(cellChar, style: style);
              }),
            );
          }),
          const SizedBox(height: 1),
          // Layer indicators
          Text(
            'Layers: ${_showTerrain ? "T" : "-"}${_showOwnership ? "O" : "-"}${_showTowns ? "N" : "-"}${_showFog ? "F" : "-"} '
            '(1-4 toggle)',
            style: TextStyle(color: Colors.gray),
          ),
        ],
      ),
    );
  }

  Component _buildContextPanel() {
    final prov = _currentProvince;

    // Get owner name from game players
    String getOwnerName(String? ownerId) {
      if (ownerId == null) return 'Unclaimed';
      for (final player in game.players) {
        if (player.id == ownerId) {
          return player.displayName;
        }
      }
      return ownerId;
    }

    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Province Info', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
          const SizedBox(height: 1),
          if (prov == null)
            Text('No data available', style: TextStyle(color: Colors.gray))
          else ...[
            // Name
            Text('Name: ${prov.displayName ?? prov.id}', style: TextStyle(color: Colors.yellow)),
            const SizedBox(height: 1),
            
            // Owner
            Text('Owner: ${getOwnerName(prov.ownerId)}'),
            const SizedBox(height: 1),
            
            // Terrain
            Text('Terrain: ${_showTerrain ? prov.terrain : "[hidden]"}'),
            const SizedBox(height: 1),
            
            // Fort Level
            Text('Fort: ${_showTowns ? prov.fortLevel : "[hidden]"}'),
            const SizedBox(height: 1),
            
            // Town Development
            Text('Town Dev: ${_showTowns ? prov.townDevelopmentLevel : "[hidden]"}'),
            const SizedBox(height: 1),
            
            // Visibility (placeholder - would come from PlayerView)
            Text('Visibility: ${_getVisibilityIcon(_Visibility.full)} full'),
          ],
          
          const SizedBox(height: 2),
          // Selection mode indicator
          Text(
            'Mode: ${_tileMode ? "Tile" : "Province"} (Tab to toggle)',
            style: TextStyle(color: Colors.gray),
          ),
          
          if (_tileMode) ...[
            const SizedBox(height: 1),
            Text('Tile: (${_cursorX * 2}, ${_cursorY * 2})', style: TextStyle(color: Colors.yellow)),
            Text('Terrain: Plains', style: TextStyle(color: Colors.gray)),
            Text('Improvement: None', style: TextStyle(color: Colors.gray)),
            Text('Units: None', style: TextStyle(color: Colors.gray)),
          ],
          
          const Spacer(),
          // Help
          Text('Controls:', style: TextStyle(color: Colors.cyan)),
          Text('Arrows/hjkl: Move', style: TextStyle(color: Colors.gray)),
          Text('Tab/w/s: Mode', style: TextStyle(color: Colors.gray)),
          Text('1-4: Layers  r: Region', style: TextStyle(color: Colors.gray)),
          Text('Esc: Back', style: TextStyle(color: Colors.gray)),
        ],
      ),
    );
  }

}

enum _Visibility { full, revealed, fog }
