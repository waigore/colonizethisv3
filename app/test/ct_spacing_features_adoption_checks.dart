// Shared CtSpacing symmetric-literal scan (Refs #4734 Slice H).

/// Returns formatted bad-line entries for raw `EdgeInsets.symmetric` named
/// args in [source] whose horizontal/vertical literals belong to the migrated
/// token set {8, 12, 16, 20, 24}.
List<String> ctSpacingSymmetricBadLines(String source) {
  final symmetricArg = RegExp(
    r'\b(horizontal|vertical):\s*(8|12|16|20|24)(?:\.0)?\s*[,)]',
  );
  final lines = source.split('\n');
  final List<String> bad = <String>[];
  var insideSymmetric = false;
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final trimmed = raw.trimLeft();
    if (trimmed.startsWith('//')) continue;
    final opensSymmetric = raw.contains('EdgeInsets.symmetric(');
    if (opensSymmetric) {
      final sym = RegExp(
        r'EdgeInsets\.symmetric\([^)]*\b(horizontal|vertical):\s*(?:8|12|16|20|24)(?:\.0)?\s*[,)]',
      );
      if (sym.hasMatch(raw)) {
        bad.add('  L${i + 1}: ${raw.trim()}');
      }
      final openIdx = raw.lastIndexOf('EdgeInsets.symmetric(');
      final tail = raw.substring(openIdx);
      if (!tail.contains(')')) {
        insideSymmetric = true;
      }
      continue;
    }
    if (insideSymmetric) {
      if (symmetricArg.hasMatch(raw)) {
        bad.add('  L${i + 1}: ${raw.trim()}');
      }
      if (raw.contains(')')) {
        insideSymmetric = false;
      }
    }
  }
  return bad;
}
