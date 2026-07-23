/// Scoped fleet tracking for tile-scoped naval panel hosts.

import 'dart:async';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'naval_units_panel_widget.dart';

mixin NavalUnitsPanelScopeTracking on State<NavalUnitsPanel> {
  final Set<String> visibleScopedFleetIds = <String>{};
  StreamSubscription<NavalMoveFleetRequestedEvent>? moveRequestedSub;
  bool pendingScopedAutoCloseAfterMove = false;
}
