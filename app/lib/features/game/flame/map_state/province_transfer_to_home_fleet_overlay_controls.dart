import 'package:flutter/material.dart';

/// MAP20001 Naval Transfer to Home Fleet props (Refs #4625).
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
