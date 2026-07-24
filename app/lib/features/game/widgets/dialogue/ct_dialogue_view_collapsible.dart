// Collapsible single-option line scan for [CtDialogueView].
// Split from `ct_dialogue_view.dart` to keep the host under the repo
// file-size target (Refs #3878, #4117 de-part).

import 'package:jenny/jenny.dart';

import 'ct_dialogue_view_base.dart';

/// Collapsible line+option scan for [CtDialogueView] (Refs #4117 de-part).
mixin CtDialogueViewCollapsible on CtDialogueViewBase {
  /// Narrative lines (by identity) in the current node that are *immediately*
  /// followed by a [DialogueChoice] with exactly one option, mapped to that
  /// option's evaluated label via [collapsibleLabels] at the same index.
  final List<DialogueLine> collapsibleLines = [];

  /// Evaluated single-option labels parallel to [collapsibleLines].
  final List<String> collapsibleLabels = [];

  void rebuildCollapsibleLinesForNode(Node node) {
    collapsibleLines.clear();
    collapsibleLabels.clear();
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
        collapsibleLines.add(entry);
        collapsibleLabels.add(option.text);
      }
    }
  }

  /// Returns the evaluated single-option label for [line] when it is
  /// immediately followed by a single-option choice in the current node
  /// (identity match against [collapsibleLines]); otherwise `null`.
  String? collapsedLabelFor(DialogueLine line) {
    for (var i = 0; i < collapsibleLines.length; i++) {
      if (identical(collapsibleLines[i], line)) return collapsibleLabels[i];
    }
    return null;
  }
}
