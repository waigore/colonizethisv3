import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/region_map/region_map_widget_bindings.dart';
import 'ct_region_map.dart';

/// Keyboard, scroll-wheel, hover, and pinch/pan input chrome for [CtRegionMap].
mixin CtRegionMapViewportMixin on State<CtRegionMap> {
  CtRegionMapGame get regionMapGame;
  double get scaleGestureStartMultiplier;
  set scaleGestureStartMultiplier(double value);

  Widget buildRegionMapViewport() {
    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          // Zoom in
          const SingleActivator(LogicalKeyboardKey.equal): () =>
              regionMapGame.zoomBy(1.1),
          const SingleActivator(LogicalKeyboardKey.add): () =>
              regionMapGame.zoomBy(1.1),
          const SingleActivator(LogicalKeyboardKey.numpadAdd): () =>
              regionMapGame.zoomBy(1.1),
          // Zoom out
          const SingleActivator(LogicalKeyboardKey.minus): () =>
              regionMapGame.zoomBy(0.9),
          const SingleActivator(LogicalKeyboardKey.numpadSubtract): () =>
              regionMapGame.zoomBy(0.9),
        },
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final dx = event.scrollDelta.dx;
              final dy = event.scrollDelta.dy;
              // Pick the dominant scroll axis; treat horizontal as zoom as well (Magic Mouse support).
              final primary = dy.abs() >= dx.abs() ? dy : -dx;
              if (primary == 0) return;
              final factor = primary < 0 ? 1.1 : 0.9;
              regionMapGame.zoomBy(factor);
            }
          },
          child: MouseRegion(
            onHover: (event) =>
                regionMapGame.updateHoverFromLocal(event.localPosition),
            onExit: (_) =>
                regionMapGame.updateHoverFromLocal(const Offset(-1, -1)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) {
                scaleGestureStartMultiplier = regionMapGame.zoomMultiplier;
              },
              onScaleUpdate: (details) {
                if (details.pointerCount > 1) {
                  regionMapGame.setZoomMultiplierAbsolute(
                    scaleGestureStartMultiplier * details.scale,
                  );
                }
                regionMapGame.panBy(details.focalPointDelta);
              },
              child: buildRegionMapGameViewport(regionMapGame),
            ),
          ),
        ),
      ),
    );
  }
}
