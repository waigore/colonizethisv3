part of 'production_allocation_row_buttons.dart';

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
    final surface = ProductionStepButtonSurface(
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
