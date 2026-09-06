import 'package:flutter/material.dart';

/// MAP20001 Naval Sail / Move props (Refs #4735).
class ProvinceOverlaySailMoveOverlayControls {
  const ProvinceOverlaySailMoveOverlayControls({
    this.showSailMove = false,
    this.sailMoveEnabled = false,
    this.sailMoveTooltip = '',
    this.onSailMoveTap,
  });

  static const hidden = ProvinceOverlaySailMoveOverlayControls();

  final bool showSailMove;
  final bool sailMoveEnabled;
  final String sailMoveTooltip;
  final VoidCallback? onSailMoveTap;
}
