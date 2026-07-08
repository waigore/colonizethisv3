import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'production_allocation_repeat_timing.dart';

part 'production_allocation_row_buttons_surface.dart';
part 'production_allocation_row_buttons_step.dart';
part 'production_allocation_row_buttons_action.dart';

/// Fixed tappable surface size for the dark editorial-monocle step buttons
/// per `SPEC/ui/production-panel.md` § Allocation step buttons. The leading
/// icon keeps its existing ~14–16 px size centered inside this surface.
const double kProductionAllocationStepButtonSize = 26;

/// Disabled opacity for the entire step-button surface (gradient + border +
/// icon), per `SPEC/ui/production-panel.md` § Allocation step buttons (R14:
/// "disabled at 0.3 opacity").
const double kProductionAllocationStepButtonDisabledOpacity = 0.3;

typedef ProductionDesiredMapReader = Map<String, int> Function();

/// Returns **true** if the map changed (repeat may continue).
typedef ProductionAllocationTryStep = bool Function(Map<String, int> current);
