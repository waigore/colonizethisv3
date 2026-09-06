// AC1 barrel signature pins — delegates to topic smoke registrars (Refs #2336).
import 'e2e_helpers_barrel_reexport_naval_smoke.dart';
import 'e2e_helpers_barrel_reexport_snapshot_smoke.dart';

void registerE2eHelpersBarrelReexportSmokeTests() {
  registerE2eHelpersBarrelReexportNavalSmokeTests();
  registerE2eHelpersBarrelReexportSnapshotSmokeTests();
}
