import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugConsoleOverlayPanel extends StatefulWidget {
  const DebugConsoleOverlayPanel({
    required this.bus,
    required this.humanPlayerId,
    required this.onClose,
    super.key,
  });

  final AppEventBus bus;
  final String humanPlayerId;
  final VoidCallback onClose;

  @override
  State<DebugConsoleOverlayPanel> createState() =>
      _DebugConsoleOverlayPanelState();
}

class _DebugConsoleOverlayPanelState extends State<DebugConsoleOverlayPanel> {
  final DebugConsoleHistory _history = DebugConsoleHistory();
  final DebugConsoleCommandExecutor _executor =
      const DebugConsoleCommandExecutor();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _lines = <String>[
    'Debug console ready. Type /help for commands.',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final rawInput = _controller.text;
    final result = _executor.executeRaw(
      rawInput: rawInput,
      humanPlayerId: widget.humanPlayerId,
    );
    setState(() {
      _lines.add('> ${rawInput.trim()}');
      _lines.add(result.message);
    });
    if (!result.isError) {
      _history.push(rawInput);
      _controller.clear();
      for (final event in result.events) {
        widget.bus.emit(event);
      }
    }
    widget.bus.emit(ShowSnackBarEvent(message: result.message));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final older = _history.older();
      if (older != null) {
        _controller
          ..text = older
          ..selection = TextSelection.collapsed(offset: older.length);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final newer = _history.newer();
      if (newer != null) {
        _controller
          ..text = newer
          ..selection = TextSelection.collapsed(offset: newer.length);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 420,
        height: 220,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Debug Console',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close debug console',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  color: Colors.black54,
                  child: ListView(
                    children: _lines
                        .map(
                          (line) => Text(
                            line,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Focus(
                onKeyEvent: _handleKey,
                child: TextField(
                  key: const ValueKey<String>('debug-console-input'),
                  focusNode: _focusNode,
                  controller: _controller,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '/spawn_civilian explorer 1',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
