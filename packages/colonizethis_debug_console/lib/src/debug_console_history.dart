class DebugConsoleHistory {
  void push(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) {
      _resetCursor();
      return;
    }
    if (_entries.isEmpty || _entries.last != trimmed) {
      _entries.add(trimmed);
    }
    _resetCursor();
  }

  String? older() {
    if (_entries.isEmpty) {
      return null;
    }
    if (_cursor == null) {
      _cursor = _entries.length - 1;
      return _entries[_cursor!];
    }
    if (_cursor! <= 0) {
      return _entries.first;
    }
    _cursor = _cursor! - 1;
    return _entries[_cursor!];
  }

  String? newer() {
    if (_entries.isEmpty) {
      return null;
    }
    if (_cursor == null) {
      return '';
    }
    if (_cursor! >= _entries.length - 1) {
      _resetCursor();
      return '';
    }
    _cursor = _cursor! + 1;
    return _entries[_cursor!];
  }

  List<String> snapshot() => List<String>.unmodifiable(_entries);

  final List<String> _entries = <String>[];
  int? _cursor;

  void _resetCursor() {
    _cursor = null;
  }
}
