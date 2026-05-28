import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../widgets/ct_gradients.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'production_allocation_repeat_timing.dart';

/// Fixed tappable surface size for the dark editorial-monocle step buttons
/// per `SPEC/ui/production-panel.md` § Allocation step buttons. The leading
/// icon keeps its existing ~14–16 px size centered inside this surface.
const double kProductionAllocationStepButtonSize = 26;

/// Disabled opacity for the entire step-button surface (gradient + border +
/// icon), per `SPEC/ui/production-panel.md` § Allocation step buttons (R14:
/// "disabled at 0.3 opacity").
const double kProductionAllocationStepButtonDisabledOpacity = 0.3;

/// Wraps an icon child in the dark editorial-monocle step-button chrome
/// (26 × 26 surface with [CtGradients.buttonGradient] inside a 1 px
/// `EditorialMonoclePalette.border` outline) and fades the entire surface
/// to [kProductionAllocationStepButtonDisabledOpacity] when disabled.
class _ProductionAllocationStepButtonSurface extends StatelessWidget {
  const _ProductionAllocationStepButtonSurface({
    required this.enabled,
    required this.iconAssetPath,
    required this.iconSize,
  });

  final bool enabled;
  final String iconAssetPath;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : kProductionAllocationStepButtonDisabledOpacity,
      child: SizedBox(
        width: kProductionAllocationStepButtonSize,
        height: kProductionAllocationStepButtonSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: CtGradients.buttonGradient,
            border: Border.all(
              color: EditorialMonoclePalette.border,
              width: 1,
            ),
          ),
          child: Center(
            child: StrictAssetIcon(
              assetPath: iconAssetPath,
              width: iconSize,
              height: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

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
    final surface = _ProductionAllocationStepButtonSurface(
      enabled: widget.enabled,
      iconAssetPath: path,
      iconSize: widget.iconSize,
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
          child: surface,
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
    final surface = _ProductionAllocationStepButtonSurface(
      enabled: enabled,
      iconAssetPath: path,
      iconSize: iconSize,
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
            child: surface,
          ),
        ),
      ),
    );
  }
}
