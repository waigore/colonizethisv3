// Shared "Moving to: …" label formatter for military / naval draft moves.
// Do not merge full tree builders — only the destination line string. Refs #4018.

/// Formats a pending draft-move destination label for units panels.
String formatDraftMoveDestinationLine(
  String destinationDisplayName, {
  String? parenthetical,
}) {
  if (parenthetical == null || parenthetical.isEmpty) {
    return 'Moving to: $destinationDisplayName';
  }
  return 'Moving to: $destinationDisplayName ($parenthetical)';
}
