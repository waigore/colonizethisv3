import 'dart:async';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../shared/base_units_panel.dart';
import 'naval_units_panel.dart';

/// Shared lifecycle fields for [NavalUnitsPanel] mixins (Refs #4117 de-part).
mixin NavalUnitsPanelStateBase on BaseUnitsPanelState<NavalUnitsPanel> {
  final Set<String> visibleScopedFleetIds = <String>{};
  StreamSubscription<NavalMoveFleetRequestedEvent>? moveRequestedSub;
  bool pendingScopedAutoCloseAfterMove = false;

  @override
  void dispose() {
    moveRequestedSub?.cancel();
    super.dispose();
  }
}
