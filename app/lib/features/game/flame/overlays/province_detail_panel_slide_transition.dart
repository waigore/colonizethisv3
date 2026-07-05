import 'package:flutter/material.dart';

/// Slide axis for [ProvinceDetailPanelSlideTransition].
enum ProvinceDetailPanelSlideAxis {
  /// Bottom sheet: enters from below (`Offset(0, 1)`).
  bottom,

  /// Side panel: enters from the right (`Offset(1, 0)`).
  end,
}

/// Animated open/close wrapper for province detail panel hosts.
///
/// SPEC: `SPEC/ui/province-sea-zone-detail-overlay.md` § Interaction (panel
/// motion); `SPEC/ui/game-map-narrow-detail-overlay-slot.md` § Open / close
/// motion. Refs #2865 S8.
class ProvinceDetailPanelSlideTransition extends StatelessWidget {
  const ProvinceDetailPanelSlideTransition({
    required this.visible,
    required this.axis,
    required this.child,
    super.key,
  });

  /// When `false`, the panel plays the exit slide then unmounts.
  final bool visible;

  final ProvinceDetailPanelSlideAxis axis;

  /// Panel subtree when [visible] is `true` (overlay + host chrome).
  final Widget child;

  /// Enter/exit duration for both hosts (SPEC § Panel motion).
  static const Duration kDuration = Duration(milliseconds: 200);

  static const Key kTransitionHostKey = Key('province_detail_panel_slide');

  Offset _beginOffset() {
    return switch (axis) {
      ProvinceDetailPanelSlideAxis.bottom => const Offset(0, 1),
      ProvinceDetailPanelSlideAxis.end => const Offset(1, 0),
    };
  }

  Alignment _stackAlignment() {
    return switch (axis) {
      ProvinceDetailPanelSlideAxis.bottom => Alignment.bottomCenter,
      ProvinceDetailPanelSlideAxis.end => Alignment.centerRight,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      key: kTransitionHostKey,
      duration: kDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.passthrough,
          alignment: _stackAlignment(),
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (transitionChild, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: _beginOffset(),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: offsetAnimation,
          child: transitionChild,
        );
      },
      child: visible
          ? KeyedSubtree(
              key: const ValueKey<String>('province_detail_panel_open'),
              child: child,
            )
          : const SizedBox.shrink(
              key: ValueKey<String>('province_detail_panel_closed'),
            ),
    );
  }
}
