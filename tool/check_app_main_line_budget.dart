// Caps colonizethis_app `by_package_role.main` at 61_000 lines per
// `pytool/project_stats.py`. Refs #3942 headroom (was 60_000 under #3878);
// raised for named save/load dialogs (Refs #3959); raised again for load-game
// list paging/delete/metadata UI (Refs #3985); raised for full game-session
// clear API + pause-disable-while-resolving wiring (Refs #3989); raised for
// session-clear isolation test hooks on GameService (Refs #3989 assurance);
// raised for province Economic Extraction/Available condensed UI (Refs #4002);
// raised for bundled map theme catalog + Settings dialog (Refs #4088);
// raised for MAP20001 tile capital-link + partial-yield reason UI (Refs #4149, #4150);
// raised for disconnected-tile blocked extraction map discs (Refs #4151);
// raised for order-rejected feed deep-link routing (Refs #4146);
// raised for GAME60001 Market bid-goods indicator and bid-type cap gate (Refs #4170);
// raised for GAME70001 Victory panel compact wide layout + minimap annotations (Refs #4165);
// raised for GAME80001 Development panel shell, read model, and map (Slice A Refs #4175);
// raised for GAME80001 Assign improve, disconnected dialog, and Road first (Slices B–C Refs #4175);
// raised for GAME90001 Counsel screen + GAME20001 industry counsel stars (Refs #4190);
// raised for GAME20001 turn-resolution read-only counsel navigation (Refs #4190);
// raised for Marionette debug binding + Ct discoverability (Refs #4199);
// raised for GAME70001 Victory standings↔minimap selection + OW progress bars (Refs #4197);
// raised for DLG31001–DLG31003 naval mission assign + UNIT30001/map menu (Refs #4213);
// raised for DLG20001 invasion intel summaries on move army dialog (Refs #4216);
// raised for Choose-tech effect summary and Details at assignment (Refs #4222);
// raised for UNIT10001 Spy relocate + hold/leave intel decision support (Refs #4219);
// raised for wave-11 app refactor file splits (Flame, Victory, event handler; Refs #4224);
// raised for GAME60001 first-right Market cue, Deal Book labels, overseas-profit ledger (Refs #4226).
// raised for GAME60001 Market wide two-column compact rows (Refs #4227).
// raised for UNIT20001 generals strip + DLG20001 invasion capacity warn (Refs #4233).
// raised for forces food readiness + invasion/combat underfed soft warns (Refs #4242).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _packageName = 'colonizethis_app';
const _maxMainLines = 68000;

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
