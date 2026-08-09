import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'civilian_units_panel.dart';
import 'civilian_units_panel_build.dart';
import 'civilian_units_panel_list.dart';
import 'civilian_units_panel_state_base.dart';

/// Stateful implementation for [CivilianUnitsPanel] (Refs #4117 de-part).
class CivilianUnitsPanelState extends ConsumerState<CivilianUnitsPanel>
    with
        CivilianUnitsPanelStateBase,
        CivilianUnitsPanelList,
        CivilianUnitsPanelBuild {
  @override
  Widget build(BuildContext context) => buildCivilianUnitsPanel(context);
}
