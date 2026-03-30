// Pause/Options screen. SPEC/tui/screens/pause-options.md.

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';

final _log = tuiLogger();

/// Pause menu with exit to main menu and settings options.
class PauseOptionsScreen extends StatefulComponent {
  const PauseOptionsScreen({
    super.key,
    required this.onNavigate,
    required this.onExitToMainMenu,
  });

  final void Function(CttermRoute) onNavigate;
  final void Function() onExitToMainMenu;

  @override
  State<PauseOptionsScreen> createState() => _PauseOptionsScreenState();
}

class _PauseOptionsScreenState extends State<PauseOptionsScreen> {
  // Selected menu item (0 = Exit to Main Menu, 1 = Settings, 2 = Debug log)
  int _selectedIndex = 0;
  // Show exit confirmation
  bool _showExitConfirm = false;

  static const _menuItems = [
    'Exit to Main Menu',
    'Settings',
    'Debug log',
  ];

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: _showExitConfirm ? _buildExitConfirm() : _buildMenu(),
    );
  }

  Component _buildExitConfirm() {
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Exit to Main Menu?'),
          const Text('Any unsaved progress will be lost.'),
          const SizedBox(height: 1),
          const Text('[Y] Yes  [N] No'),
        ],
      ),
    );
  }

  Component _buildMenu() {
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 2),
          const Text('=== PAUSE ===', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          ..._buildMenuItems(),
          const SizedBox(height: 2),
          const Text('[Esc/B] Back to Game  [Enter] Select'),
          const Text('[W/S or Up/Down] Navigate'),
        ],
      ),
    );
  }

  List<Component> _buildMenuItems() {
    return List.generate(_menuItems.length, (index) {
      final isSelected = index == _selectedIndex;
      final prefix = isSelected ? '> ' : '  ';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Text('$prefix${_menuItems[index]}'),
      );
    });
  }

  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();

    // Handle exit confirmation
    if (_showExitConfirm) {
      if (c == 'y' || key == LogicalKey.enter) {
        _log.d('exiting to main menu from pause');
        component.onExitToMainMenu();
        return true;
      } else if (c == 'n' || key == LogicalKey.escape) {
        setState(() => _showExitConfirm = false);
        return true;
      }
      return false;
    }

    // Escape or B - back to game
    if (key == LogicalKey.escape || c == 'b') {
      component.onNavigate(CttermRoute.inGameShell);
      return true;
    }

    // W or Up - previous item
    if (c == 'w' || key == LogicalKey.arrowUp) {
      setState(() {
        if (_selectedIndex > 0) {
          _selectedIndex--;
        }
      });
      return true;
    }

    // S or Down - next item
    if (c == 's' || key == LogicalKey.arrowDown) {
      setState(() {
        if (_selectedIndex < _menuItems.length - 1) {
          _selectedIndex++;
        }
      });
      return true;
    }

    // Enter - execute selected action
    if (key == LogicalKey.enter) {
      if (_selectedIndex == 0) {
        // Exit to Main Menu
        setState(() => _showExitConfirm = true);
        return true;
      } else if (_selectedIndex == 1) {
        // Settings (navigate to settings screen)
        component.onNavigate(CttermRoute.settings);
        return true;
      } else if (_selectedIndex == 2) {
        // Debug log (navigate to debug log viewer)
        component.onNavigate(CttermRoute.debugLogViewer);
        return true;
      }
    }

    return false;
  }
}
