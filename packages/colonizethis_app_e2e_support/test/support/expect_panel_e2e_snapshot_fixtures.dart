// Snapshot reset for e2eExpect*PanelMatchesE2eSnapshot pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';

void resetPanelE2eSnapshots() {
  ctE2eLastPanelSnapshot = null;
  ctE2eCivilianPanelSnapshot = null;
  ctE2eNavalPanelSnapshot = null;
  ctE2eProductionPanelSnapshot = null;
}
