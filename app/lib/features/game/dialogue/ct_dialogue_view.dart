import 'dart:async';

import 'package:colonizethis_app/package_logger.dart';
import 'package:jenny/jenny.dart';

/// Flutter/Jenny dialogue view that drives UI via callbacks and completers.
/// SPEC/ui/dialogue-presentation.md, SPEC/ai/dialogue-content-and-yarn.md.
class CtDialogueView extends DialogueView {
  CtDialogueView({CtLogger? logger})
    : _log = logger ?? packageLogger('dialogue');

  final CtLogger _log;

  DialogueLine? _currentLine;
  DialogueChoice? _currentChoice;
  DialogueLine? _contextLine;
  void Function(DialogueLine? line, DialogueChoice? choice)? onStateChanged;

  Completer<void>? _lineCompleter;
  Completer<int?>? _choiceCompleter;

  DialogueLine? get currentLine => _currentLine;
  DialogueChoice? get currentChoice => _currentChoice;

  /// The narrative line most recently presented, retained through the
  /// transient null state after [advanceLine] and through the subsequent
  /// choice so consumers can keep the message visible while option buttons
  /// render together with it (SPEC/ui/ct-dialogue-view.md § Combined
  /// line+choice presentation). Reset to `null` once a choice resolves or the
  /// dialogue finishes so only the *immediately preceding* line accompanies a
  /// choice — earlier lines in a multi-line node do not linger. Refs #3628.
  DialogueLine? get contextLine => _contextLine;

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
    _log.d('line start "${line.text}"');
    _currentLine = line;
    _contextLine = line;
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
    _log.d('choice start ${choice.options.length} options');
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

  @override
  FutureOr<void> onDialogueFinish() {
    _log.d('dialogue finish');
    _currentLine = null;
    _currentChoice = null;
    _contextLine = null;
    _lineCompleter = null;
    _choiceCompleter = null;
    onStateChanged?.call(null, null);
  }

  @override
  void onDialogueStart() {
    _log.d('dialogue start');
  }
}
