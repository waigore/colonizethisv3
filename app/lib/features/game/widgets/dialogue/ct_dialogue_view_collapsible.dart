// Collapsible single-option line scan for [CtDialogueView].
// Split from `ct_dialogue_view.dart` to keep the host under the repo
// file-size target (Refs #3878).

part of 'ct_dialogue_view.dart';

extension _CtDialogueViewCollapsible on CtDialogueView {
  void rebuildCollapsibleLinesForNode(Node node) {
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

  /// Returns the evaluated single-option label for [line] when it is
  /// immediately followed by a single-option choice in the current node
  /// (identity match against [_collapsibleLines]); otherwise `null`.
  String? collapsedLabelFor(DialogueLine line) {
    for (var i = 0; i < _collapsibleLines.length; i++) {
      if (identical(_collapsibleLines[i], line)) return _collapsibleLabels[i];
    }
    return null;
  }
}
