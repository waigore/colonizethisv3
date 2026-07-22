// Responsive chrome, header, and shared body text styles for the province overlay.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_widget.dart';
import 'province_sea_zone_detail_overlay_close_button.dart';
import 'province_sea_zone_detail_overlay_support.dart';

extension ProvinceSeaZoneDetailOverlayChrome on ProvinceSeaZoneDetailOverlay {
  Widget buildResponsivePanel(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
    OverlayContent content,
  ) {
    final maxHeight = resolveOverlayMaxHeight(context, constraints, isNarrow);
    return Padding(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.ml),
      child: content.sections,
    );
  }
}
