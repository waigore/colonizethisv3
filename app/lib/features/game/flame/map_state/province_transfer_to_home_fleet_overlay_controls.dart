import 'package:flutter/material.dart';

/// Overlay Naval Transfer to Home Fleet control props (Refs #4625).
class ProvinceTransferToHomeFleetOverlayControls {
  const ProvinceTransferToHomeFleetOverlayControls({
    this.showTransferToHomeFleet = false,
    this.transferToHomeFleetEnabled = false,
    this.transferToHomeFleetTooltip = '',
    this.onTransferToHomeFleetTap,
  });

  static const hidden = ProvinceTransferToHomeFleetOverlayControls();

  final bool showTransferToHomeFleet;
  final bool transferToHomeFleetEnabled;
  final String transferToHomeFleetTooltip;
  final VoidCallback? onTransferToHomeFleetTap;
}
