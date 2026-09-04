import 'dart:io';

import 'package:path/path.dart' as p;

/// Ensures OpenCode/Grok skill files are thin shims of `.cursor/skills/`.
int runCheckSkillShims(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  void logInfo(String line) {
    if (info != null) {
      info(line);
    } else {
      stdout.writeln(line);
    }
  }

  void logErr(String line) {
    if (err != null) {
      err(line);
    } else {
      stderr.writeln(line);
    }
  }

  final violations = <String>[];

  final cursorSkills = Directory(p.join(repoRoot, '.cursor', 'skills'));
  if (!cursorSkills.existsSync()) {
    violations.add('missing .cursor/skills/');
    _emit(violations, logInfo, logErr);
    return 1;
  }

  final names = <String>[];
  for (final entity in cursorSkills.listSync()) {
    if (entity is! Directory) {
      continue;
    }
    final skillMd = File(p.join(entity.path, 'SKILL.md'));
    if (!skillMd.existsSync()) {
      continue;
    }
    names.add(p.basename(entity.path));
  }
  names.sort();

  for (final name in names) {
    final cursorPath = p.join(repoRoot, '.cursor', 'skills', name, 'SKILL.md');
    final cursorFile = File(cursorPath);
    final cursorContent = cursorFile.readAsStringSync();
    if (cursorContent.contains('Thin OpenCode shim') ||
        cursorContent.contains('Thin Grok shim')) {
      violations.add(
        '.cursor/skills/$name/SKILL.md must be the source of truth, not a shim',
      );
    }

    for (final host in ['.opencode', '.grok']) {
      final rel = '$host/skills/$name/SKILL.md';
      final shimPath = p.join(repoRoot, rel);
      final type = FileSystemEntity.typeSync(shimPath, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        violations.add('missing $rel');
        continue;
      }
      if (type == FileSystemEntityType.link) {
        violations.add('$rel must be a regular file, not a symlink');
        continue;
      }
      final content = File(shimPath).readAsStringSync();
      if (!content.contains('Source of truth')) {
        violations.add('$rel must contain "Source of truth"');
      }
      if (!content.contains('.cursor/skills/$name/SKILL.md')) {
        violations.add('$rel must point at .cursor/skills/$name/SKILL.md');
      }
      final lineCount = content.split('\n').length;
      if (lineCount > 80) {
        violations.add(
          '$rel is $lineCount lines; shims must stay thin (copy workflow into Cursor only)',
        );
      }
    }
  }

  _emit(violations, logInfo, logErr);
  return violations.isEmpty ? 0 : 1;
}

void _emit(
  List<String> violations,
  void Function(String line) logInfo,
  void Function(String line) logErr,
) {
  if (violations.isEmpty) {
    logInfo('check_skill_shims: no violations found.');
    return;
  }
  logErr('check_skill_shims: found ${violations.length} violation(s):');
  for (final violation in violations) {
    logErr(' - $violation');
  }
}

void main() {
  exit(runCheckSkillShims(Directory.current.path));
}
