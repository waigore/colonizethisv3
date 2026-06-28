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

  /// Narrative lines (by identity) in the current node that are *immediately*
  /// followed by a [DialogueChoice] with exactly one option, mapped to that
  /// option's evaluated label via [_collapsibleLabels] at the same index.
  /// Rebuilt per node in [onNodeStart]. Refs #3628.
  final List<DialogueLine> _collapsibleLines = [];
  final List<String> _collapsibleLabels = [];

  /// The single trivial option label to render on the *combined* step when the
  /// active line is collapsible (see [pendingSingleOptionLabel]); `null` when
  /// the active line is a normal advance-only line.
  String? _pendingSingleOptionLabel;

  /// Set when the player taps the combined line+option button so the trailing
  /// single-option [onChoiceStart] auto-selects index 0 instead of rendering a
  /// second step. Refs #3628.
  bool _autoSelectSingleOption = false;

  DialogueLine? get currentLine => _currentLine;
  DialogueChoice? get currentChoice => _currentChoice;

  /// Non-null only while the active line is immediately followed by a choice
  /// with exactly one option. Consumers render a **single combined step**: the
  /// narrative line text plus one confirmation button labelled with this value
  /// (the Yarn option text, e.g. `I shall.`), wired to
  /// [confirmCombinedLineOption]. `null` for normal advance-only lines and for
  /// any choice that has two or more options. Refs #3628.
  String? get pendingSingleOptionLabel => _pendingSingleOptionLabel;

  /// The narrative line most recently presented, retained through the
  /// transient null state after [advanceLine] and through any subsequent
  /// multi-option choice so consumers can keep the message visible while option
  /// buttons render together with it (SPEC/ui/ct-dialogue-view.md § Combined
  /// line+choice presentation). Reset to `null` once a choice resolves or the
  /// dialogue finishes so only the *immediately preceding* line accompanies a
  /// choice — earlier lines in a multi-line node do not linger. For a line
  /// followed by a *single* trivial option the two steps are collapsed (see
  /// [pendingSingleOptionLabel]) so the choice step never renders. Refs #3628.
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

  /// Call when the user taps the single combined line+option button (rendered
  /// when [pendingSingleOptionLabel] is non-null). Advances the active line;
  /// the trailing single-option [onChoiceStart] then auto-selects index 0 so
  /// the narrative is shown once and confirmed with one tap. Refs #3628.
  void confirmCombinedLineOption() {
    _autoSelectSingleOption = true;
    advanceLine();
  }

  @override
  FutureOr<void> onNodeStart(Node node) {
    _collapsibleLines.clear();
    _collapsibleLabels.clear();
    final entries = node.toList(growable: false);
    for (var i = 0; i + 1 < entries.length; i++) {
      final entry = entries[i];
      final next = entries[i + 1];
      if (entry is DialogueLine &&
          next is DialogueChoice &&
          next.options.length == 1) {
        // Evaluating the sole option here mirrors what the runner does before
        // delivering the choice (DialogueChoice.processInDialogueRunner), so
        // this introduces no failure mode the node would not already hit.
        final option = next.options.first;
        option.evaluate();
        _collapsibleLines.add(entry);
        _collapsibleLabels.add(option.text);
      }
    }
  }

  @override
  FutureOr<bool> onLineStart(DialogueLine line) {
    _log.d('line start "${line.text}"');
    _currentLine = line;
    _contextLine = line;
    _currentChoice = null;
    _pendingSingleOptionLabel = _collapsedLabelFor(line);
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

  @override
  FutureOr<void> onDialogueFinish() {
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

  /// Returns the evaluated single-option label for [line] when it is
  /// immediately followed by a single-option choice in the current node
  /// (identity match against [_collapsibleLines]); otherwise `null`.
  String? _collapsedLabelFor(DialogueLine line) {
    for (var i = 0; i < _collapsibleLines.length; i++) {
      if (identical(_collapsibleLines[i], line)) return _collapsibleLabels[i];
    }
    return null;
  }

  @override
  void onDialogueStart() {
    _log.d('dialogue start');
  }
}
