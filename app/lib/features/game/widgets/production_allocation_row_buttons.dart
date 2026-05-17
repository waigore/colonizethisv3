import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'production_allocation_repeat_timing.dart';

typedef ProductionDesiredMapReader = Map<String, int> Function();

/// Returns **true** if the map changed (repeat may continue).
typedef ProductionAllocationTryStep = bool Function(Map<String, int> current);

/// **+** or **−** with tap and long-press repeat per SPEC/ui/production-panel.md.
///
/// Uses [GestureDetector] long-press recognition (same ~500 ms threshold as
/// [kProductionAllocationRepeatInitialDelay]) plus [Timer.periodic] at
/// [kProductionAllocationRepeatInterval] for repeats — survives parent rebuilds
/// from allocation updates better than raw [Listener] timers.
class ProductionAllocationStepButton extends StatefulWidget {
  const ProductionAllocationStepButton({
    super.key,
    required this.enabled,
    required this.readDesired,
    required this.tryStepFromCurrent,
    required this.semanticLabel,
    required this.tooltip,
    required this.assetFileName,
    this.iconSize = 15,
  });

  final bool enabled;
  final ProductionDesiredMapReader readDesired;
  final ProductionAllocationTryStep tryStepFromCurrent;
  final String semanticLabel;
  final String tooltip;
  final String assetFileName;
  final double iconSize;

  @override
  State<ProductionAllocationStepButton> createState() =>
      _ProductionAllocationStepButtonState();
}

class _ProductionAllocationStepButtonState
    extends State<ProductionAllocationStepButton> {
  Timer? _repeatTimer;

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _onLongPress() {
    if (!widget.enabled) {
      return;
    }
    if (!widget.tryStepFromCurrent(widget.readDesired())) {
      return;
    }
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(kProductionAllocationRepeatInterval, (_) {
      if (!mounted) {
        return;
      }
      if (!widget.tryStepFromCurrent(widget.readDesired())) {
        _stopRepeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = '$kAppIconAssetPrefix${widget.assetFileName}';
    final icon = Opacity(
      opacity: widget.enabled ? 1 : 0.35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: StrictAssetIcon(
          assetPath: path,
          width: widget.iconSize,
          height: widget.iconSize,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled
              ? () {
                  widget.tryStepFromCurrent(widget.readDesired());
                }
              : null,
          onLongPress: widget.enabled ? _onLongPress : null,
          onLongPressEnd: (_) => _stopRepeat(),
          onLongPressCancel: () => _stopRepeat(),
          child: icon,
        ),
      ),
    );
  }
}

/// Single tap (maximize / clear) icon control.
class ProductionAllocationActionIconButton extends StatelessWidget {
  const ProductionAllocationActionIconButton({
    super.key,
    required this.enabled,
    required this.readDesired,
    required this.onPressedFromCurrent,
    required this.semanticLabel,
    required this.tooltip,
    required this.assetFileName,
    this.iconSize = 15,
  });

  final bool enabled;
  final ProductionDesiredMapReader readDesired;
  final void Function(Map<String, int> current) onPressedFromCurrent;
  final String semanticLabel;
  final String tooltip;
  final String assetFileName;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final path = '$kAppIconAssetPrefix$assetFileName';
    final child = Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: StrictAssetIcon(
          assetPath: path,
          width: iconSize,
          height: iconSize,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onPressedFromCurrent(readDesired()) : null,
            child: child,
          ),
        ),
      ),
    );
  }
}
