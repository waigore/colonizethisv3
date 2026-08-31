// Responsive chrome, header, and shared body text styles for the province overlay.

import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kUiSurfaceOpenBudgetMs;
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'province_overlay_wide_lazy_sections.dart';
import 'province_sea_zone_detail_overlay_close_button.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_widget.dart';

extension ProvinceSeaZoneDetailOverlayChrome on ProvinceSeaZoneDetailOverlay {
  Widget buildResponsivePanel(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
    OverlayContent content,
  ) {
    final maxHeight = resolveOverlayMaxHeight(context, constraints, isNarrow);
    return ProvinceOverlayInteractiveReadyMarker(
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.m),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: CtPanel(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: isNarrow ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildOverlayHeader(context),
                Flexible(child: buildOverlayBody(isNarrow, content)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double resolveOverlayMaxHeight(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
  ) {
    final mqSize = MediaQuery.sizeOf(context);
    final thirdScreen = mqSize.height * 0.33;
    final isFullWidthNarrow =
        isNarrow && (constraints.maxWidth >= mqSize.width - 8);
    if (!isNarrow) {
      return constraints.maxHeight;
    }
    if (!constraints.maxHeight.isFinite) {
      return thirdScreen;
    }
    if (constraints.maxHeight <= thirdScreen + 1) {
      return constraints.maxHeight;
    }
    if (isFullWidthNarrow) {
      return thirdScreen;
    }
    return constraints.maxHeight;
  }

  Widget buildOverlayHeader(BuildContext context) {
    final l10n = appL10n(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: CtSpacing.ml,
        right: CtSpacing.m,
        top: CtSpacing.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isProvinceSeaZoneOverlaySeaZone(region, displayId)
                  ? l10n.provinceOverlay_titleSeaZone
                  : l10n.provinceOverlay_titleProvince,
              style: overlayTitleStyle(context),
            ),
          ),
          OverlayCloseButton(onClose: onClose),
        ],
      ),
    );
  }

  Widget buildOverlayBody(bool isNarrow, OverlayContent content) {
    if (isNarrow) {
      return CtTabStrip(
        lazyTabBodies: true,
        tabLabels: content.tabLabels,
        tabViews: content.tabViews
            .map(
              (w) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: w,
              ),
            )
            .toList(),
        contentPadding: const EdgeInsets.all(CtSpacing.ml),
      );
    }
    final lazyKey = GlobalKey<ProvinceOverlayWideLazySectionsState>();
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        lazyKey.currentState?.handleScroll(notification.metrics);
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CtSpacing.ml),
        child: ProvinceOverlayWideLazySections(
          key: lazyKey,
          sections: content.sectionSpecs,
          eagerSectionCount: content.lazyWideDeferredFromIndex,
        ),
      ),
    );
  }
}

/// Logs [CtAppPerf.provinceOverlay.interactiveReady] once per overlay mount (Refs #4690).
class ProvinceOverlayInteractiveReadyMarker extends StatefulWidget {
  const ProvinceOverlayInteractiveReadyMarker({super.key, required this.child});

  final Widget child;

  @override
  State<ProvinceOverlayInteractiveReadyMarker> createState() =>
      _ProvinceOverlayInteractiveReadyMarkerState();
}

class _ProvinceOverlayInteractiveReadyMarkerState
    extends State<ProvinceOverlayInteractiveReadyMarker> {
  static final _log = packageLogger('perf');

  @override
  void initState() {
    super.initState();
    ctAppPerfSurfaceOpenBegin('provinceOverlay');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final elapsedMs = ctAppPerfSurfaceOpenInteractiveReady('provinceOverlay');
      if ((kProfileMode || kReleaseMode) && elapsedMs != null) {
        final host = ctAppPerfSurfaceOpenBindingHost();
        final line =
            'ui_surface_open surface=provinceOverlay elapsed_ms=$elapsedMs '
            'budget_ms=$kUiSurfaceOpenBudgetMs host=$host';
        _log.i(line);
        // stdout for profile `flutter drive` evidence capture (Refs #4690).
        debugPrint(line);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
