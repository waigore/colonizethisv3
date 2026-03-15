// Debug log viewer. SPEC/program/debug-log-viewer.md. Screen ID 100020.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;
import 'package:session_log_buffer/session_log_buffer.dart';

/// Debug log viewer: scrollable session logs with multiselect filters. [B] Back.
class DebugLogViewerScreen extends StatefulComponent {
  const DebugLogViewerScreen({
    super.key,
    required this.onBack,
  });

  final void Function() onBack;

  @override
  State<DebugLogViewerScreen> createState() => _DebugLogViewerScreenState();
}

class _DebugLogViewerScreenState extends State<DebugLogViewerScreen> {
  Set<String> _selectedPrefixes = Set<String>.from(knownPrefixes);
  Set<log_pkg.Level> _selectedLevels = Set<log_pkg.Level>.from(knownLevels);
  int _scrollOffset = 0;

  List<SessionLogEntry> get _filtered =>
      SessionLogBuffer.instance.getFiltered(
        selectedPrefixes: _selectedPrefixes,
        selectedLevels: _selectedLevels,
      );

  @override
  Component build(BuildContext context) {
    final entries = _filtered;
    final lines = <String>[];
    for (final e in entries) {
      lines.addAll(e.displayLines);
    }
    final totalLines = lines.length;
    if (_scrollOffset > totalLines - 1) {
      _scrollOffset = totalLines > 0 ? totalLines - 1 : 0;
    }
    final visibleStart = _scrollOffset;
    final visibleEnd = visibleStart + 20;
    final visible = lines.sublist(
      visibleStart,
      visibleEnd > lines.length ? lines.length : visibleEnd,
    );

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final key = event.logicalKey;
        final c = event.character?.toLowerCase();
        if (key == LogicalKey.escape || c == 'b') {
          component.onBack();
          return true;
        }
        if (key == LogicalKey.arrowUp || c == 'w') {
          setState(() {
            if (_scrollOffset > 0) _scrollOffset--;
          });
          return true;
        }
        if (key == LogicalKey.arrowDown || c == 's') {
          setState(() {
            if (_scrollOffset < totalLines - 1) _scrollOffset++;
          });
          return true;
        }
        if (c != null && c.length == 1) {
          final num = int.tryParse(c);
          if (num != null && num >= 1 && num <= knownPrefixes.length) {
            final p = knownPrefixes[num - 1];
            setState(() {
              if (_selectedPrefixes.contains(p)) {
                _selectedPrefixes = Set.from(_selectedPrefixes)..remove(p);
              } else {
                _selectedPrefixes = Set.from(_selectedPrefixes)..add(p);
              }
            });
            return true;
          }
          final levelKeys = ['d', 'i', 'w', 'e'];
          final levelIdx = levelKeys.indexOf(c);
          if (levelIdx >= 0 && levelIdx < knownLevels.length) {
            final l = knownLevels[levelIdx];
            setState(() {
              if (_selectedLevels.contains(l)) {
                _selectedLevels = Set<log_pkg.Level>.from(_selectedLevels)
                  ..remove(l);
              } else {
                _selectedLevels = Set<log_pkg.Level>.from(_selectedLevels)
                  ..add(l);
              }
            });
            return true;
          }
        }
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(1),
            child: Text(
              'Debug log — [B] Back  [W/S] Scroll  [1-${knownPrefixes.length}] Package  [D/I/W/E] Level',
              style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              'Package: ${_selectedPrefixes.join(' ')}  Level: ${_selectedLevels.map((log_pkg.Level l) => l.name).join(' ')}',
              style: TextStyle(color: Colors.gray),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  visible[index],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
