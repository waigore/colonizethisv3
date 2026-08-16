import 'package:flutter/material.dart';

/// Overlay Naval Detach and sail control props (Refs #4448).
class ProvinceDetachAndSailOverlayControls {
  const ProvinceDetachAndSailOverlayControls({
    this.showDetachAndSail = false,
    this.detachAndSailEnabled = false,
    this.detachAndSailTooltip = '',
    this.onDetachAndSailTap,
  });

  static const hidden = ProvinceDetachAndSailOverlayControls();

  final bool showDetachAndSail;
  final bool detachAndSailEnabled;
  final String detachAndSailTooltip;
  final VoidCallback? onDetachAndSailTap;
}
