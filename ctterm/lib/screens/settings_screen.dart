// Settings screen. SPEC/tui/ctterm.md, SPEC/tui/screens/settings.md.

import 'package:ctterm/package_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

final _log = packageLogger();

/// Available terminal themes.
enum TerminalTheme {
  light('L', 'Light'),
  dark('D', 'Dark');

  const TerminalTheme(this.key, this.label);
  final String key;
  final String label;
}

/// Settings screen: terminal theme selection.
class SettingsScreen extends StatefulComponent {
  const SettingsScreen({
    super.key,
    required this.onBack,
    this.initialTheme,
    this.onThemeChanged,
  });

  final void Function() onBack;
  final TerminalTheme? initialTheme;
  /// Callback when theme is changed.
  final void Function(TerminalTheme)? onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TerminalTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = component.initialTheme ?? TerminalTheme.dark;
    _log.d('init, theme=${_selectedTheme.name}');
  }

  void _selectTheme(TerminalTheme theme) {
    setState(() => _selectedTheme = theme);
    _log.d('theme selected=${theme.name}');
    // Notify parent to apply theme
    component.onThemeChanged?.call(theme);
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final key = event.logicalKey;
        if (key == LogicalKey.escape) {
          component.onBack();
          return true;
        }
        final c = event.character?.toLowerCase();
        if (c == 'l') {
          _selectTheme(TerminalTheme.light);
          return true;
        }
        if (c == 'd') {
          _selectTheme(TerminalTheme.dark);
          return true;
        }
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              'Terminal Theme',
              style: TextStyle(color: Colors.gray),
            ),
            const SizedBox(height: 1),
            ...TerminalTheme.values.map((theme) => _themeRow(theme)),
            const SizedBox(height: 2),
            Text(
              '[Esc] Back to Main Menu',
              style: TextStyle(color: Colors.gray),
            ),
          ],
        ),
      ),
    );
  }

  Component _themeRow(TerminalTheme theme) {
    final isSelected = theme == _selectedTheme;
    final check = isSelected ? '✓ ' : '  ';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('[${theme.key}] ', style: TextStyle(color: Colors.cyan)),
          Text(
            '$check${theme.label}',
            style: isSelected
                ? TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }
}
