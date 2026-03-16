import 'dart:async';

import 'package:jenny/jenny.dart';
import 'package:logger/logger.dart';

/// Flutter/Jenny dialogue view that drives UI via callbacks and completers.
/// SPEC/ui/dialogue-presentation.md, SPEC/ai/dialogue-content-and-yarn.md.
class CtDialogueView extends DialogueView {
  CtDialogueView({Logger? logger}) : _log = logger ?? Logger();

  final Logger _log;

  DialogueLine? _currentLine;
  DialogueChoice? _currentChoice;
  void Function(DialogueLine? line, DialogueChoice? choice)? onStateChanged;

  Completer<void>? _lineCompleter;
  Completer<int?>? _choiceCompleter;

  DialogueLine? get currentLine => _currentLine;
  DialogueChoice? get currentChoice => _currentChoice;

  /// Call when the user has read the line and taps to continue.
  void advanceLine() {
    final c = _lineCompleter;
    if (c != null && !c.isCompleted) {
      _lineCompleter = null;
      c.complete();
    }
  }

  /// Call when the user selects an option (0-based index).
  void selectOption(int index) {
    final c = _choiceCompleter;
    if (c != null && !c.isCompleted) {
      _choiceCompleter = null;
      c.complete(index);
    }
  }

  @override
  FutureOr<bool> onLineStart(DialogueLine line) {
    _log.d('ui:dialogue: line start "${line.text}"');
    _currentLine = line;
    _currentChoice = null;
    _lineCompleter = Completer<void>();
    onStateChanged?.call(_currentLine, _currentChoice);
    return _lineCompleter!.future.then((_) {
      _currentLine = null;
      onStateChanged?.call(null, _currentChoice);
      return true;
    });
  }

  @override
  FutureOr<int?> onChoiceStart(DialogueChoice choice) {
    _log.d('ui:dialogue: choice start ${choice.options.length} options');
    _currentLine = null;
    _currentChoice = choice;
    _choiceCompleter = Completer<int?>();
    onStateChanged?.call(_currentLine, _currentChoice);
    return _choiceCompleter!.future.then((index) {
      _currentChoice = null;
      onStateChanged?.call(null, null);
      return index;
    });
  }

  @override
  FutureOr<void> onDialogueFinish() {
    _log.d('ui:dialogue: dialogue finish');
    _currentLine = null;
    _currentChoice = null;
    _lineCompleter = null;
    _choiceCompleter = null;
    onStateChanged?.call(null, null);
  }

  @override
  void onDialogueStart() {
    _log.d('ui:dialogue: dialogue start');
  }
}
