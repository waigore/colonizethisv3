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
// raised for shell cargo hold tap details + tight colour tiers (Refs #4253).
// raised for MAP20001 Build road Engineer tile shortcut (Refs #4260).
// raised for work-order cost and affordability at assign time (Refs #4262);
// raised for GAME30001 diplomacy ready-first actions + More expander (Refs #4265).
// raised for OVL50001 intervention choice-picker situation and Effect lines (Refs #4267).
// raised for OVL70001 market fill summary feed row with Deal Book deep-link (Refs #4270).
// raised for MAP20001 Purchase land Merchant tile shortcut (Refs #4274).
// raised for GAME90001 Trade Counsel tab + GAME60001 Market counsel entry (Refs #4282).
// raised for MAP fort icons + MAP20001 fort status and Build fort shortcut (Refs #4280);
// raised for combined Trade Counsel + fort merge headroom after dev integration (Refs #4282).
// raised for UNIT60001 Train Naval role and cargo/combat gist rows (Refs #4300).
// raised for GAME80001 lazy per-region Development panel read model (Refs #4175 perf).
// raised for GAME90001 Military Counsel tab + UNIT20001 counsel entry (Refs #4307).
// raised for OVL70001 realm economy turn-summary feed row (Refs #4308).
// raised for GAME80001 Development panel map snapshot cache + deferred paint (Refs #4175 Slice E).
// raised for MAP20001 Upgrade town political shortcut + level gist (Refs #4316).
// raised for Military Counsel budget headroom after dev integration (Refs #4307).
// raised for MAP20001 Upgrade town merge headroom on military counsel branch (Refs #4316).
// raised for UNIT50001 Train Military benefit vs cost gist rows (Refs #4324).
// raised for MAP10001 extraction-disc legend + popover teaching chrome (Refs #4367).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _packageName = 'colonizethis_app';
// raised for military counsel + train military benefit merge headroom (Refs #4307, #4324).
// raised for MAP20001 Build port Engineer tile shortcut + Port status (Refs #4332).
// raised for GAME90001 Development Counsel tab + GAME80001 counsel entry (Refs #4332 Slice 2).
// raised for GAME40001 sequential multi-slot research preview + turn funding header (Refs #4335).
// raised for DLG31002 Blockade/Beachhead fog-honest target intel (Refs #4340).
// raised for MAP20001 Establish Consulate Political shortcut (Refs #4346).
// raised for combined #4340+#4346+#4350 merge headroom (DLG31002 intel,
// Consulate shortcut, Move/Invade overlay Military shortcuts).
// raised for UNIT40001 civilian role gists on Train Civilians rows (Refs #4366).
// raised for MAP10001 capital-link disconnected land highlight (Refs #4370).
// raised for OVL40001 call-to-arms Join/Refuse Effect lines (Refs #4364).
// raised for MAP20001 Tile details disclosure dialog + connectivity teaching (Refs #4369).
// raised for MAP20001 Build railroad Rail Builder tile shortcut (Refs #4383).
// raised for MAP10001 tappable army stack markers (Refs #4384).
// raised for combined #4366+#4367+#4369+#4370+#4383+#4384 merge headroom.
// raised for named map resource/improvement/road layers (Refs #4388).
// raised for DLG20002 / DLG31003 unit-picker composition lines (Refs #4385).
// raised for combined #4370+#4383+#4384+#4385+#4388 merge headroom (measured 77_122).
// raised for MAP10001 owner/sight hover readout + MAP20001 Political Sight (Refs #4406; measured 77_490).
// raised for MAP10001 improvement headroom marks + teaching chip (Refs #4408; measured 77_976).
// raised for DIPL20001 grant/subsidy Submit-commit + Deal Book player copy
// merge headroom (Refs #4415, #4414; measured 78_020).
// raised for DIPL20001 grant/subsidy Submit-commit + Deal Book player copy
// merge headroom (Refs #4415, #4414; measured 78_020).
// raised for MAP20001 Naval Blockade/Beachhead overlay (Refs #4413).
// raised for Home Army detach-then-move from map overlay (Refs #4407; measured 78_256).
// raised for SHEL10002 Quick Start (Refs #4416; measured 77_621).
// raised for Declare War named third-party courts on confirm (Refs #4409; measured 78_068).
// raised for combined #4414+#4415+#4407+#4416+#4409 merge headroom (measured 78_506).
// raised for CMPT10001 force/fort/Details on combat mode choice (Refs #4438; measured 78_737).
// raised for GAME20001 Labour row cost/upkeep (Refs #4432; measured 78_800).
// raised for MAP20001 Station spy Civilian shortcut + #4438 merge (Refs #4439; measured 79_147).
// raised for MAP20001 Naval Blockade/Beachhead overlay + #4439 merge (Refs #4413; measured 79_517).
// raised for combined #4438+#4432+#4439 merge headroom (measured 79_441).
// raised for MAP30001 tile context radial + More dialog (Refs #4440; measured 80_223).
// raised for combined #4440+#4432 merge headroom (measured 80_517).
// raised for combined #4413+#4440 merge headroom (measured 80_940).
// raised for Home Fleet detach-then-sail from the map (Refs #4448; measured 81_342).
// raised for MAP10001 Old World province race chip (Refs #4451; measured 81_681).
// raised for DLG60001 staged decree review + #4451 merge (Refs #4469; measured 82_528).
// raised for GAME80001 Development Assign preview + #4469 merge (Refs #4472; measured 82_729).
// raised for GAME30003 Intelligence Council + #4472 merge (Refs #4476; measured 83_233).
// raised for MAP20001 Political owner standing + Offer Peace (Refs #4479; measured 83_694).
// raised for MAP10001 last-turn spatial playback + #4479 merge (Refs #4486; measured 84_334).
// raised for GAME40001 Technology Tree assign-from-node + #4486 merge (Refs #4498; measured 84_885).
// raised for GAME60001 Deal Book leftover reasons (Refs #4500; measured 85_318).
// raised for MAP10001 labour/feeding tab-bar indicator (Refs #4506; measured 85_954).
// raised for GAME40001 research seat finish-time line (Refs #4511; measured 86_127).
// raised for Blockade capital-link UI + MAP20001 under-blockade status (Refs #4516; measured 86_075).
// raised for DLG50001 Your-court block + turn-event buffer (Refs #4532; measured 87_183).
// raised for MAP10001 treasury forecast gold-HUD details (Refs #4560; measured 87_687).
// raised for MAP20001 remaining civilian work radial shortcuts (Refs #4570; measured 88_240).
// raised for DLG30001 Move fleet hostile destination intel (Refs #4573; measured 88_116).
// raised for wave-20 host splits (Refs #4582; measured 88_684).
const _maxMainLines = 88700;

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

  final result = Process.runSync('python3', [
    script,
    '--json',
  ], workingDirectory: repoRoot);
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
