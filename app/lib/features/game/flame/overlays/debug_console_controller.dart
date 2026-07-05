import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugConsoleController {
  DebugConsoleController({
    required this.bus,
    required this.humanPlayerId,
    required this.readOnlyContextProvider,
    required this.onClose,
  }) : _lines = <String>['Debug console ready. Type /help for commands.'];

  final AppEventBus bus;
  final String humanPlayerId;
  final DebugConsoleReadOnlyContext? Function() readOnlyContextProvider;
  final VoidCallback onClose;

  final DebugConsoleHistory _history = DebugConsoleHistory();
  final DebugConsoleCommandExecutor _executor =
      const DebugConsoleCommandExecutor();
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final List<String> _lines;

  List<String> get lines => List.unmodifiable(_lines);

  void dispose() {
    textController.dispose();
    focusNode.dispose();
  }

  String submit() {
    final rawInput = textController.text;
    final result = _executor.executeRaw(
      rawInput: rawInput,
      humanPlayerId: humanPlayerId,
      readOnlyContext: readOnlyContextProvider(),
    );
    _lines
      ..add('> ${rawInput.trim()}')
      ..add(result.message);
    if (!result.isError) {
      _history.push(rawInput);
      textController.clear();
      for (final event in result.events) {
        bus.emit(event);
      }
    }
    bus.emit(ShowSnackBarEvent(message: result.message));
    return result.message;
  }

  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      onClose();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final older = _history.older();
      if (older != null) {
        textController
          ..text = older
          ..selection = TextSelection.collapsed(offset: older.length);
      }
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final newer = _history.newer();
      if (newer != null) {
        textController
          ..text = newer
          ..selection = TextSelection.collapsed(offset: newer.length);
      }
      return true;
    }
    return false;
  }
}
