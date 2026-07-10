import 'dart:async';

import 'package:colonizethis_app/package_logger.dart';
import 'package:jenny/jenny.dart';

part 'ct_dialogue_view_collapsible.dart';
part 'ct_dialogue_view_jenny.dart';

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
  FutureOr<void> onNodeStart(Node node) => handleNodeStart(node);

  @override
  FutureOr<bool> onLineStart(DialogueLine line) => handleLineStart(line);

  @override
  FutureOr<int?> onChoiceStart(DialogueChoice choice) =>
      handleChoiceStart(choice);

  @override
  FutureOr<void> onDialogueFinish() => handleDialogueFinish();

  @override
  void onDialogueStart() => handleDialogueStart();
}
