import 'dart:io';

import 'package:path/path.dart' as p;

final _rawSubscriptionListPattern = RegExp(
  r'\bList\s*<\s*StreamSubscription\s*(?:<[^>]*>)?\s*>',
);
final _inferredSubscriptionListPattern = RegExp(
  r'<\s*StreamSubscription\s*(?:<[^>]*>)?\s*>\s*\[',
);

/// Enforces app feature lifecycle cleanup convention:
/// multi-subscription state should use SubscriptionTracker instead of raw lists.
///
/// SPEC: SPEC/program/repo-lint.md and SPEC/program/app-ui-wiring.md
int runCheckSubscriptionTracker(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final featuresDir = Directory(p.join(repoRoot, 'app', 'lib', 'features'));
  if (!featuresDir.existsSync()) {
    logE('check_subscription_tracker: app/lib/features not found.');
    return 1;
  }

  final violations = <String>[];
  for (final entity in featuresDir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p.relative(entity.path, from: repoRoot);
    final lines = entity.readAsLinesSync();
    var inBlockComment = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final codeLine = _stripCommentOnlyLine(line, inBlockComment);
      inBlockComment = codeLine.inBlockComment;
      if (codeLine.text.isEmpty) {
        continue;
      }
      if (!_rawSubscriptionListPattern.hasMatch(codeLine.text) &&
          !_inferredSubscriptionListPattern.hasMatch(codeLine.text)) {
        continue;
      }
      violations.add(
        '$relativePath:${i + 1}: use SubscriptionTracker instead of a raw StreamSubscription list',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_subscription_tracker: no violations found.');
    return 0;
  }

  logE(
    'check_subscription_tracker: found ${violations.length} raw StreamSubscription list violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

({String text, bool inBlockComment}) _stripCommentOnlyLine(
  String line,
  bool wasInBlockComment,
) {
  var trimmed = line.trim();
  var inBlockComment = wasInBlockComment;
  if (inBlockComment) {
    final endIndex = trimmed.indexOf('*/');
    if (endIndex == -1) {
      return (text: '', inBlockComment: true);
    }
    trimmed = trimmed.substring(endIndex + 2).trimLeft();
    inBlockComment = false;
  }
  if (trimmed.startsWith('//')) {
    return (text: '', inBlockComment: inBlockComment);
  }
  final blockStart = trimmed.indexOf('/*');
  if (blockStart == 0) {
    final blockEnd = trimmed.indexOf('*/', blockStart + 2);
    if (blockEnd == -1) {
      return (text: '', inBlockComment: true);
    }
    trimmed = trimmed.substring(blockEnd + 2).trimLeft();
  }
  return (text: trimmed, inBlockComment: inBlockComment);
}

void main() {
  exit(runCheckSubscriptionTracker(Directory.current.path));
}
