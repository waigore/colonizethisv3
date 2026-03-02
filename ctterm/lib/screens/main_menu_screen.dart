// Main Menu. SPEC/ui/main-menu.md, SPEC/tui/ctterm.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/menu_logic.dart';
import 'package:ctterm/save_service.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Main menu: New Game, Load Game (enabled only when saves exist), Settings, Quit.
class MainMenuScreen extends StatefulComponent {
  const MainMenuScreen({
    super.key,
    required this.onNewGame,
    required this.onLoadGame,
    required this.onSettings,
    required this.onQuit,
    this.dataDirOverride,
  });

  final void Function() onNewGame;
  final void Function() onLoadGame;
  final void Function() onSettings;
  final void Function() onQuit;
  final String? dataDirOverride;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _loadGameEnabled = false;
  bool _savesChecked = false;

  @override
  void initState() {
    super.initState();
    _checkSaves();
  }

  Future<void> _checkSaves() async {
    try {
      final ids = await listGameIds(component.dataDirOverride)
          .timeout(const Duration(seconds: 5), onTimeout: () => <String>[]);
      _log.d('tui:menu: listGameIds count=${ids.length}');
      if (!mounted) return;
      setState(() {
        _loadGameEnabled = isLoadGameEnabled(ids);
        _savesChecked = true;
      });
    } catch (e, st) {
      _log.w('tui:menu: checkSaves failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadGameEnabled = false;
        _savesChecked = true;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (!_savesChecked) return false;
        final key = event.logicalKey;
        if (key == LogicalKey.enter || key == LogicalKey.space) {
          // Use current selection (we use shortcuts below instead for simplicity)
          return false;
        }
        // Shortcuts: n, l, s, q
        final c = event.character?.toLowerCase();
        if (c == 'n') {
          component.onNewGame();
          return true;
        }
        if (c == 'l' && _loadGameEnabled) {
          component.onLoadGame();
          return true;
        }
        if (c == 's') {
          component.onSettings();
          return true;
        }
        if (c == 'q') {
          component.onQuit();
          return true;
        }
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ColonizeThis', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            _menuRow('N', 'New Game', true, component.onNewGame),
            _menuRow('L', 'Load Game', _loadGameEnabled, component.onLoadGame),
            if (!_savesChecked)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Checking saves...',
                  style: TextStyle(color: Colors.gray),
                ),
              )
            else if (!_loadGameEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'No save games found',
                  style: TextStyle(color: Colors.gray),
                ),
              ),
            _menuRow('S', 'Settings', true, component.onSettings),
            _menuRow('Q', 'Quit', true, component.onQuit),
            const SizedBox(height: 2),
            Text('v0.1.0', style: TextStyle(color: Colors.gray)),
          ],
        ),
      ),
    );
  }

  Component _menuRow(
    String key,
    String label,
    bool enabled,
    void Function() onTap,
  ) {
    final style = enabled
        ? null
        : TextStyle(color: Colors.gray);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('[$key] ', style: TextStyle(color: Colors.cyan)),
          GestureDetector(
            onTap: enabled ? onTap : null,
            child: Text(label, style: style),
          ),
        ],
      ),
    );
  }
}
