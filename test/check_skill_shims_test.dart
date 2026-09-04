import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_skill_shims.dart';

void main() {
  test('repo OpenCode and Grok skills are thin Cursor shims', () {
    final stdoutLines = <String>[];
    final stderrLines = <String>[];
    final code = runCheckSkillShims(
      Directory.current.path,
      info: stdoutLines.add,
      err: stderrLines.add,
    );
    expect(code, 0, reason: stderrLines.join('\n'));
    expect(stdoutLines.join('\n'), contains('no violations found'));
  });

  test('fails when an OpenCode skill is missing or is a symlink', () {
    final tempDir = Directory.systemTemp.createTempSync('check_skill_shims_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    File(p.join(tempDir.path, '.cursor', 'skills', 'demo', 'SKILL.md'))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
---
name: demo
description: Demo skill
---

# Demo
''');
    File(p.join(tempDir.path, '.grok', 'skills', 'demo', 'SKILL.md'))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
---
name: demo
description: Demo skill
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/demo/SKILL.md`

Read the full file and follow it exactly.
''');

    final stderrLines = <String>[];
    final code = runCheckSkillShims(tempDir.path, err: stderrLines.add);
    expect(code, 1);
    expect(
      stderrLines.join('\n'),
      contains('missing .opencode/skills/demo/SKILL.md'),
    );
  });
}
