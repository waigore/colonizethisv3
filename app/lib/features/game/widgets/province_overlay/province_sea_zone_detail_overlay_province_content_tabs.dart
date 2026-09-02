/// Tab labels, views, and stacked sections for revealed province overlay content.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_support.dart';

OverlayContent assembleProvinceOverlayTabContent({
  required AppLocalizations l10n,
  required Widget Function() political,
  required Widget Function() tileSection,
  required Widget Function() economic,
  required Widget Function() militarySection,
  required Widget Function() civilianSection,
  required Widget Function() naval,
}) {
  return overlayProvinceSectionBundle(
    l10n: l10n,
    political: political,
    tileSection: tileSection,
    economic: economic,
    military: militarySection,
    civilian: civilianSection,
    naval: naval,
  );
}
