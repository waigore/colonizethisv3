// Load Game screen. SPEC/tui/screens/load-game.md, SPEC/tui/ctterm.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/save_service.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Load Game: lists saved games, allows load or delete.
class LoadGameScreen extends StatefulComponent {
  const LoadGameScreen({
    super.key,
    required this.onLoad,
    required this.onDelete,
    required this.onBack,
    this.dataDirOverride,
  });

  final void Function(String gameId) onLoad;
  final void Function(String gameId) onDelete;
  final void Function() onBack;
  final String? dataDirOverride;

  @override
  State<LoadGameScreen> createState() => _LoadGameScreenState();
}

class _LoadGameScreenState extends State<LoadGameScreen> {
  List<SaveSummary> _saves = [];
  int _selectedIndex = 0;
  bool _loading = true;
  bool _confirmingDelete = false;

  @override
  void initState() {
    super.initState();
    _loadSaves();
  }

  Future<void> _loadSaves() async {
    final saves = await listSaves(component.dataDirOverride);
    setState(() {
      _saves = saves;
      _loading = false;
      if (_saves.isNotEmpty && _selectedIndex >= _saves.length) {
        _selectedIndex = 0;
      }
    });
  }

  void _handleKey(String c) {
    if (_confirmingDelete) {
      if (c == 'y' || c == 'Y') {
        _doDelete();
      }
      setState(() => _confirmingDelete = false);
      return;
    }

    if (_saves.isEmpty) {
      if (c == 'b' || c == 'B' || c == 'escape') {
        component.onBack();
      }
      return;
    }

    switch (c) {
      case 'arrowup':
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1 + _saves.length) % _saves.length;
        });
        break;
      case 'arrowdown':
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _saves.length;
        });
        break;
      case 'l':
      case 'L':
        _doLoad();
        break;
      case 'd':
      case 'D':
        setState(() => _confirmingDelete = true);
        break;
      case 'b':
      case 'B':
      case 'escape':
        component.onBack();
        break;
    }
  }

  void _doLoad() {
    if (_saves.isEmpty || _selectedIndex >= _saves.length) return;
    final gameId = _saves[_selectedIndex].gameId;
    _log.d('tui:save: load gameId=$gameId');
    component.onLoad(gameId);
  }

  void _doDelete() {
    if (_saves.isEmpty || _selectedIndex >= _saves.length) return;
    final gameId = _saves[_selectedIndex].gameId;
    _log.i('tui:save: delete gameId=$gameId');
    component.onDelete(gameId);
    setState(() {
      _saves.removeAt(_selectedIndex);
      if (_selectedIndex >= _saves.length && _saves.isNotEmpty) {
        _selectedIndex = _saves.length - 1;
      }
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (_loading) return false;
        final key = event.logicalKey;
        if (key == LogicalKey.arrowUp) {
          _handleKey('arrowup');
          return true;
        }
        if (key == LogicalKey.arrowDown) {
          _handleKey('arrowdown');
          return true;
        }
        final c = event.character?.toLowerCase();
        if (c != null) {
          _handleKey(c);
          return true;
        }
        if (key == LogicalKey.escape) {
          _handleKey('escape');
          return true;
        }
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Load Game', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            if (_loading)
              Text('Loading...', style: TextStyle(color: Colors.gray))
            else if (_saves.isEmpty)
              Text('No saved games', style: TextStyle(color: Colors.gray))
            else ...[
              // Confirmation prompt for delete
              if (_confirmingDelete)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    'Delete save? (y/n)',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else
                // List saves
                ...List.generate(_saves.length, (i) {
                  final save = _saves[i];
                  final isSelected = i == _selectedIndex;
                  final style = isSelected
                      ? TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                        )
                      : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      '${isSelected ? "> " : "  "}Turn ${save.turnNumber}, ${save.year}  ${save.humanPlayerName}',
                      style: style,
                    ),
                  );
                }),
              const SizedBox(height: 2),
              // Action hints
              Text(
                '[L] Load  [D] Delete  [B] Back  [↑↓] Select',
                style: TextStyle(color: Colors.gray),
              ),
            ],
            if (_saves.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '[B] Back',
                  style: TextStyle(color: Colors.gray),
                ),
              ),
          ],
        ),
      ),
    );
  }
}