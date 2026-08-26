import 'package:flutter/material.dart';

/// Overlay Naval Combine control props (Refs #4659).
class ProvinceNavalCombineOverlayControls {
  const ProvinceNavalCombineOverlayControls({
    this.showCombineFleets = false,
    this.combineFleetsEnabled = false,
    this.combineFleetsTooltip = '',
    this.onCombineFleetsTap,
  });

  static const hidden = ProvinceNavalCombineOverlayControls();

  final bool showCombineFleets;
  final bool combineFleetsEnabled;
  final String combineFleetsTooltip;
  final VoidCallback? onCombineFleetsTap;
}
