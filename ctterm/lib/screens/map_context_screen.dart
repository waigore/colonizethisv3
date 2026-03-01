// Map Context Screen: detailed province information, map layers, visibility, region navigation.
// SPEC/tui/ctterm.md, SPEC/tui/screens/map-context.md

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Map context screen showing detailed province information, map layers, and region navigation.
class MapContextScreen extends StatefulComponent {
  const MapContextScreen({
    super.key,
    required this.onNavigate,
  });

  final void Function(CttermRoute) onNavigate;

  @override
  State<MapContextScreen> createState() => _MapContextScreenState();
}

class _MapContextScreenState extends State<MapContextScreen> {
  // Current region (Old World / New World)
  String _currentRegion = 'Old World';
  static const List<String> _regions = ['Old World', 'New World'];

  // Map layers (toggleable)
  bool _showTerrain = true;
  bool _showOwnership = true;
  bool _showTowns = true;
  bool _showFog = true;

  // Selection state
  int _cursorX = 0;
  int _cursorY = 0;
  bool _tileMode = false; // false = province, true = tile

  // Mock map data for demonstration
  static const List<List<String>> _mapGrid = [
    ['A', 'B', 'C', 'D'],
    ['E', 'F', 'G', 'H'],
    ['I', 'J', 'K', 'L'],
    ['M', 'N', 'O', 'P'],
  ];

  // Mock province data
  static const Map<String, _ProvinceData> _provinceData = {
    'A': _ProvinceData(name: 'Londinium', owner: 'British Empire', terrain: 'Plains', resources: 'Iron', towns: 3, visibility: _Visibility.full),
    'B': _ProvinceData(name: 'Edinburgh', owner: 'British Empire', terrain: 'Hills', resources: 'Coal', towns: 2, visibility: _Visibility.full),
    'C': _ProvinceData(name: 'Dublin', owner: 'British Empire', terrain: 'Coastal', resources: 'Fish', towns: 2, visibility: _Visibility.full),
    'D': _ProvinceData(name: 'Paris', owner: 'French Kingdom', terrain: 'Plains', resources: 'Wheat', towns: 4, visibility: _Visibility.full),
    'E': _ProvinceData(name: 'Madrid', owner: 'Spanish Empire', terrain: 'Desert', resources: 'Silver', towns: 3, visibility: _Visibility.revealed),
    'F': _ProvinceData(name: 'Rome', owner: 'Italian States', terrain: 'Hill', resources: 'Marble', towns: 4, visibility: _Visibility.full),
    'G': _ProvinceData(name: 'Berlin', owner: 'Prussian State', terrain: 'Plains', resources: 'Iron', towns: 2, visibility: _Visibility.full),
    'H': _ProvinceData(name: 'Vienna', owner: 'Austrian Empire', terrain: 'Mountain', resources: 'Gold', towns: 3, visibility: _Visibility.fog),
    'I': _ProvinceData(name: 'New York', owner: 'British Empire', terrain: 'Coastal', resources: 'Furs', towns: 2, visibility: _Visibility.full),
    'J': _ProvinceData(name: 'Boston', owner: 'Colonial Rebels', terrain: 'Plains', resources: 'Timber', towns: 2, visibility: _Visibility.full),
    'K': _ProvinceData(name: 'Quebec', owner: 'British Empire', terrain: 'Forest', resources: 'Fur', towns: 1, visibility: _Visibility.revealed),
    'L': _ProvinceData(name: 'Mexico City', owner: 'Spanish Empire', terrain: 'Desert', resources: 'Silver', towns: 5, visibility: _Visibility.fog),
    'M': _ProvinceData(name: 'Havana', owner: 'Spanish Empire', terrain: 'Coastal', resources: 'Sugar', towns: 2, visibility: _Visibility.full),
    'N': _ProvinceData(name: 'Lima', owner: 'Spanish Empire', terrain: 'Coastal', resources: 'Silver', towns: 3, visibility: _Visibility.fog),
    'O': _ProvinceData(name: 'Cuzco', owner: 'Unclaimed', terrain: 'Mountain', resources: 'Gold', towns: 1, visibility: _Visibility.revealed),
    'P': _ProvinceData(name: 'Brasilia', owner: 'Portuguese Empire', terrain: 'Jungle', resources: 'Timber', towns: 1, visibility: _Visibility.fog),
  };

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
    setState(() {
      final newX = (_cursorX + dx).clamp(0, _mapGrid[0].length - 1);
      final newY = (_cursorY + dy).clamp(0, _mapGrid.length - 1);
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

  String get _currentProvinceId {
    return _mapGrid[_cursorY][_cursorX];
  }

  _ProvinceData? get _currentProvince {
    return _provinceData[_currentProvinceId];
  }

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
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region indicator
          Text('Region: $_currentRegion', style: TextStyle(color: Colors.cyan)),
          const SizedBox(height: 1),
          // Map grid
          ...List.generate(_mapGrid.length, (y) {
            return Row(
              children: List.generate(_mapGrid[y].length, (x) {
                final isSelected = x == _cursorX && y == _cursorY;
                final provId = _mapGrid[y][x];
                final prov = _provinceData[provId];
                
                String cellChar = provId;
                var style = TextStyle();
                
                if (isSelected) {
                  style = TextStyle(backgroundColor: Colors.cyan, color: Colors.black);
                  cellChar = '[$cellChar]';
                } else {
                  cellChar = ' $cellChar ';
                }

                // Apply fog styling
                if (_showFog && prov != null && prov.visibility == _Visibility.fog) {
                  style = style.copyWith(color: Colors.gray);
                } else if (_showOwnership && prov != null) {
                  // Color by owner (simplified)
                  if (prov.owner.contains('British')) {
                    style = style.copyWith(color: Colors.red);
                  } else if (prov.owner.contains('French')) {
                    style = style.copyWith(color: Colors.blue);
                  } else if (prov.owner.contains('Spanish')) {
                    style = style.copyWith(color: Colors.yellow);
                  } else if (prov.owner.contains('Unclaimed')) {
                    style = style.copyWith(color: Colors.gray);
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
    final provId = _currentProvinceId;

    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Province Info', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
          const SizedBox(height: 1),
          Text('ID: $provId', style: TextStyle(color: Colors.yellow)),
          const SizedBox(height: 1),
          
          if (prov == null)
            Text('No data available', style: TextStyle(color: Colors.gray))
          else ...[
            // Name
            Text('Name: ${prov.name}'),
            const SizedBox(height: 1),
            
            // Owner
            Text('Owner: ${_maskIfFog(prov.owner, prov.visibility)}'),
            const SizedBox(height: 1),
            
            // Terrain
            Text('Terrain: ${_showTerrain ? prov.terrain : "[hidden]"}'),
            const SizedBox(height: 1),
            
            // Resources
            Text('Resources: ${_showTerrain ? (prov.resources != null ? prov.resources : "None") : "[hidden]"}'),
            const SizedBox(height: 1),
            
            // Towns
            Text('Towns: ${_showTowns ? prov.towns : "[hidden]"}'),
            const SizedBox(height: 1),
            
            // Visibility
            Text('Visibility: ${_getVisibilityIcon(prov.visibility)} ${prov.visibility.name}'),
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

  String _maskIfFog(String value, _Visibility visibility) {
    if (visibility == _Visibility.fog) return '???';
    if (visibility == _Visibility.revealed) return '$value (revealed)';
    return value;
  }
}

enum _Visibility { full, revealed, fog }

class _ProvinceData {
  final String name;
  final String owner;
  final String terrain;
  final String? resources;
  final int towns;
  final _Visibility visibility;

  const _ProvinceData({
    required this.name,
    required this.owner,
    required this.terrain,
    required this.resources,
    required this.towns,
    required this.visibility,
  });
}
