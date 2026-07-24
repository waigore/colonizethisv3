import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'civilian_units_panel.dart';

/// Shared selection state for [CivilianUnitsPanel] mixins (Refs #4117 de-part).
mixin CivilianUnitsPanelStateBase on ConsumerState<CivilianUnitsPanel> {
  String? selectedUnitId;

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
}
