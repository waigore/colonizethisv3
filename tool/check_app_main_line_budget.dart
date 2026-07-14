// Caps colonizethis_app `by_package_role.main` at 60_150 lines per
// `pytool/project_stats.py`. Refs #3942 headroom (was 60_000 under #3878);
// raised for named save/load dialogs (Refs #3959); raised again for load-game
// list paging/delete/metadata UI (Refs #3985); raised for full game-session
// clear API + pause-disable-while-resolving wiring (Refs #3989); raised for
// session-clear isolation test hooks on GameService (Refs #3989 assurance);
// raised for province Economic Extraction/Available condensed UI (Refs #4002).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _packageName = 'colonizethis_app';
const _maxMainLines = 60150;

int runCheckAppMainLineBudget(
  String repoRoot, {
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  final script = p.join(repoRoot, 'pytool/project_stats.py');
  if (!File(script).existsSync()) {
    logE('check_app_main_line_budget: missing $script');
    return 1;
  }

  final result = Process.runSync(
    'python3',
    [script, '--json'],
    workingDirectory: repoRoot,
  );
  if (result.exitCode != 0) {
    logE(
      'check_app_main_line_budget: project_stats.py exited ${result.exitCode}',
    );
    return 1;
  }

  final stdout = result.stdout;
  if (stdout is! String || stdout.trim().isEmpty) {
    logE('check_app_main_line_budget: project_stats.py produced no output');
    return 1;
  }

  final dynamic decoded = jsonDecode(stdout);
  if (decoded is! Map) {
    logE('check_app_main_line_budget: unexpected project_stats JSON shape');
    return 1;
  }

  final byRole = decoded['by_package_role'];
  if (byRole is! Map) {
    logE('check_app_main_line_budget: missing by_package_role in stats');
    return 1;
  }

  final packageRole = byRole[_packageName];
  if (packageRole is! Map) {
    logE('check_app_main_line_budget: missing $_packageName role stats');
    return 1;
  }

  final main = packageRole['main'];
  if (main is! Map) {
    logE('check_app_main_line_budget: missing main role for $_packageName');
    return 1;
  }

  final lines = main['lines'];
  if (lines is! int) {
    logE('check_app_main_line_budget: main line count is not an integer');
    return 1;
  }

  if (lines <= _maxMainLines) {
    return 0;
  }

  logE(
    'check_app_main_line_budget: $_packageName main role is $lines lines '
    '(max $_maxMainLines per pytool/project_stats.py by_package_role.main)',
  );
  return 1;
}

void main() {
  exit(runCheckAppMainLineBudget(Directory.current.path));
}
