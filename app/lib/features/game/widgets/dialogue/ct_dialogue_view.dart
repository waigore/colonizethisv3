import 'dart:async';

import 'package:colonizethis_app/package_logger.dart';
import 'package:jenny/jenny.dart';

import 'ct_dialogue_view_base.dart';
import 'ct_dialogue_view_collapsible.dart';
import 'ct_dialogue_view_jenny.dart';

/// Flutter/Jenny dialogue view that drives UI via callbacks and completers.
/// SPEC/ui/dialogue-presentation.md, SPEC/ai/dialogue-content-and-yarn.md.
class CtDialogueView extends CtDialogueViewBase
    with CtDialogueViewCollapsible, CtDialogueViewJenny {
  CtDialogueView({CtLogger? logger}) {
    dialogueLogger = logger ?? packageLogger('dialogue');
  }

  void Function(DialogueLine? line, DialogueChoice? choice)? get onStateChanged =>
      jennyOnStateChanged;

  set onStateChanged(
    void Function(DialogueLine? line, DialogueChoice? choice)? callback,
  ) {
    jennyOnStateChanged = callback;
  }

  DialogueLine? get currentLine => jennyCurrentLine;
  DialogueChoice? get currentChoice => jennyCurrentChoice;

  /// Non-null only while the active line is immediately followed by a choice
  /// with exactly one option. Consumers render a **single combined step**: the
  /// narrative line text plus one confirmation button labelled with this value
  /// (the Yarn option text, e.g. `I shall.`), wired to
  /// [confirmCombinedLineOption]. `null` for normal advance-only lines and for
  /// any choice that has two or more options. Refs #3628.
  String? get pendingSingleOptionLabel => jennyPendingSingleOptionLabel;

  /// The narrative line most recently presented, retained through the
  /// transient null state after [advanceLine] and through any subsequent
  /// multi-option choice so consumers can keep the message visible while option
  /// buttons render together with it (SPEC/ui/ct-dialogue-view.md § Combined
  /// line+choice presentation). Reset to `null` once a choice resolves or the
  /// dialogue finishes so only the *immediately preceding* line accompanies a
  /// choice — earlier lines in a multi-line node do not linger. For a line
  /// followed by a *single* trivial option the two steps are collapsed (see
  /// [pendingSingleOptionLabel]) so the choice step never renders. Refs #3628.
  DialogueLine? get contextLine => jennyContextLine;

  /// Call when the user has read the line and taps to continue.
  void advanceLine() => jennyAdvanceLine();

  /// Call when the user selects an option (0-based index).
  void selectOption(int index) => jennySelectOption(index);

  /// Call when the user taps the single combined line+option button (rendered
  /// when [pendingSingleOptionLabel] is non-null). Advances the active line;
  /// the trailing single-option [onChoiceStart] then auto-selects index 0 so
  /// the narrative is shown once and confirmed with one tap. Refs #3628.
  void confirmCombinedLineOption() => jennyConfirmCombinedLineOption();

  @override
  FutureOr<void> onNodeStart(Node node) => jennyHandleNodeStart(node);

  @override
  FutureOr<bool> onLineStart(DialogueLine line) => jennyHandleLineStart(line);

  @override
  FutureOr<int?> onChoiceStart(DialogueChoice choice) =>
      jennyHandleChoiceStart(choice);

  @override
  FutureOr<void> onDialogueFinish() => jennyHandleDialogueFinish();

  @override
  void onDialogueStart() => jennyHandleDialogueStart();
}
