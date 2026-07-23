import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'civilian_units_panel_build.dart';
import 'civilian_units_panel_list.dart';
import 'civilian_units_panel_widget.dart';

/// Tile-scope selection held by [CivilianUnitsPanelState].
mixin CivilianUnitsPanelSelection on ConsumerState<CivilianUnitsPanel> {
  String? selectedUnitId;
}

class CivilianUnitsPanelState extends ConsumerState<CivilianUnitsPanel>
    with
        CivilianUnitsPanelSelection,
        CivilianUnitsPanelList,
        CivilianUnitsPanelBuild {
  @override
  void initState() {
    super.initState();
    selectedUnitId = widget.initialSelectedUnitId;
  }

  @override
  void didUpdateWidget(covariant CivilianUnitsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedUnitId != widget.initialSelectedUnitId) {
      selectedUnitId = widget.initialSelectedUnitId;
    }
  }

  @override
  Widget build(BuildContext context) => buildCivilianUnitsPanel(context);
}
