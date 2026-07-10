// Jenny [DialogueView] lifecycle hooks for [CtDialogueView].
// Split from `ct_dialogue_view.dart` to keep the host under the repo
// file-size target (Refs #3878).

part of 'ct_dialogue_view.dart';

extension _CtDialogueViewJenny on CtDialogueView {
  FutureOr<void> handleNodeStart(Node node) {
    rebuildCollapsibleLinesForNode(node);
  }

  FutureOr<bool> handleLineStart(DialogueLine line) {
    _log.d('line start "${line.text}"');
    _currentLine = line;
    _contextLine = line;
    _currentChoice = null;
    _pendingSingleOptionLabel = collapsedLabelFor(line);
    _lineCompleter = Completer<void>();
    onStateChanged?.call(_currentLine, _currentChoice);
    return _lineCompleter!.future.then((_) {
      _currentLine = null;
      onStateChanged?.call(null, _currentChoice);
      return true;
    });
  }

  FutureOr<int?> handleChoiceStart(DialogueChoice choice) {
    _log.d('choice start ${choice.options.length} options');
    if (_autoSelectSingleOption && choice.options.length == 1) {
      // Collapsed line+option: the player already confirmed via the combined
      // button, so select the sole option without rendering a second step.
      _autoSelectSingleOption = false;
      _pendingSingleOptionLabel = null;
      _currentLine = null;
      _currentChoice = null;
      _contextLine = null;
      onStateChanged?.call(null, null);
      return 0;
    }
    _autoSelectSingleOption = false;
    _pendingSingleOptionLabel = null;
    _currentLine = null;
    _currentChoice = choice;
    _choiceCompleter = Completer<int?>();
    onStateChanged?.call(_currentLine, _currentChoice);
    return _choiceCompleter!.future.then((index) {
      _currentChoice = null;
      _contextLine = null;
      onStateChanged?.call(null, null);
      return index;
    });
  }

  FutureOr<void> handleDialogueFinish() {
    _log.d('dialogue finish');
    _currentLine = null;
    _currentChoice = null;
    _contextLine = null;
    _pendingSingleOptionLabel = null;
    _autoSelectSingleOption = false;
    _lineCompleter = null;
    _choiceCompleter = null;
    onStateChanged?.call(null, null);
  }

  void handleDialogueStart() {
    _log.d('dialogue start');
  }
}
