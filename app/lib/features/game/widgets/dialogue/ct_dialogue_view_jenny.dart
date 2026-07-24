// Jenny [DialogueView] lifecycle hooks for [CtDialogueView].
// Split from `ct_dialogue_view.dart` to keep the host under the repo
// file-size target (Refs #3878, #4117 de-part).

import 'dart:async';

import 'package:colonizethis_app/package_logger.dart';
import 'package:jenny/jenny.dart';

import 'ct_dialogue_view_base.dart';
import 'ct_dialogue_view_collapsible.dart';

/// Jenny lifecycle and runtime state for [CtDialogueView] (Refs #4117 de-part).
mixin CtDialogueViewJenny on CtDialogueViewBase, CtDialogueViewCollapsible {
  late final CtLogger dialogueLogger;

  DialogueLine? jennyCurrentLine;
  DialogueChoice? jennyCurrentChoice;
  DialogueLine? jennyContextLine;
  void Function(DialogueLine? line, DialogueChoice? choice)? jennyOnStateChanged;

  Completer<void>? jennyLineCompleter;
  Completer<int?>? jennyChoiceCompleter;

  /// Set when the player taps the combined line+option button so the trailing
  /// single-option [onChoiceStart] auto-selects index 0 instead of rendering a
  /// second step. Refs #3628.
  bool jennyAutoSelectSingleOption = false;

  /// The single trivial option label to render on the *combined* step when the
  /// active line is collapsible (see [jennyPendingSingleOptionLabel]); `null`
  /// when the active line is a normal advance-only line.
  String? jennyPendingSingleOptionLabel;

  FutureOr<void> jennyHandleNodeStart(Node node) {
    rebuildCollapsibleLinesForNode(node);
  }

  FutureOr<bool> jennyHandleLineStart(DialogueLine line) {
    dialogueLogger.d('line start "${line.text}"');
    jennyCurrentLine = line;
    jennyContextLine = line;
    jennyCurrentChoice = null;
    jennyPendingSingleOptionLabel = collapsedLabelFor(line);
    jennyLineCompleter = Completer<void>();
    jennyOnStateChanged?.call(jennyCurrentLine, jennyCurrentChoice);
    return jennyLineCompleter!.future.then((_) {
      jennyCurrentLine = null;
      jennyOnStateChanged?.call(null, jennyCurrentChoice);
      return true;
    });
  }

  FutureOr<int?> jennyHandleChoiceStart(DialogueChoice choice) {
    dialogueLogger.d('choice start ${choice.options.length} options');
    if (jennyAutoSelectSingleOption && choice.options.length == 1) {
      // Collapsed line+option: the player already confirmed via the combined
      // button, so select the sole option without rendering a second step.
      jennyAutoSelectSingleOption = false;
      jennyPendingSingleOptionLabel = null;
      jennyCurrentLine = null;
      jennyCurrentChoice = null;
      jennyContextLine = null;
      jennyOnStateChanged?.call(null, null);
      return 0;
    }
    jennyAutoSelectSingleOption = false;
    jennyPendingSingleOptionLabel = null;
    jennyCurrentLine = null;
    jennyCurrentChoice = choice;
    jennyChoiceCompleter = Completer<int?>();
    jennyOnStateChanged?.call(jennyCurrentLine, jennyCurrentChoice);
    return jennyChoiceCompleter!.future.then((index) {
      jennyCurrentChoice = null;
      jennyContextLine = null;
      jennyOnStateChanged?.call(null, null);
      return index;
    });
  }

  FutureOr<void> jennyHandleDialogueFinish() {
    dialogueLogger.d('dialogue finish');
    jennyCurrentLine = null;
    jennyCurrentChoice = null;
    jennyContextLine = null;
    jennyPendingSingleOptionLabel = null;
    jennyAutoSelectSingleOption = false;
    jennyLineCompleter = null;
    jennyChoiceCompleter = null;
    jennyOnStateChanged?.call(null, null);
  }

  void jennyHandleDialogueStart() {
    dialogueLogger.d('dialogue start');
  }

  void jennyAdvanceLine() {
    final c = jennyLineCompleter;
    if (c != null && !c.isCompleted) {
      jennyLineCompleter = null;
      c.complete();
    }
  }

  void jennySelectOption(int index) {
    final c = jennyChoiceCompleter;
    if (c != null && !c.isCompleted) {
      jennyChoiceCompleter = null;
      c.complete(index);
    }
  }

  void jennyConfirmCombinedLineOption() {
    jennyAutoSelectSingleOption = true;
    jennyAdvanceLine();
  }
}
