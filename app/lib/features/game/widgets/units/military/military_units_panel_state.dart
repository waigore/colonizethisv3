import 'package:flutter/material.dart';

import '../shared/base_units_panel.dart';
import 'military_units_panel.dart';
import 'military_units_panel_build.dart';
import 'military_units_panel_dialogs.dart';

/// Stateful implementation for [MilitaryUnitsPanel] (Refs #4117 de-part).
class MilitaryUnitsPanelState extends BaseUnitsPanelState<MilitaryUnitsPanel>
    with MilitaryUnitsPanelDialogs, MilitaryUnitsPanelBuild {
  @override
  Widget build(BuildContext context) => buildMilitaryUnitsPanel(context);
}
