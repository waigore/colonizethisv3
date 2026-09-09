/// MAP20001 Train {type} control (Consulate / Counter-espionage family).
///
/// SPEC: `SPEC/ui/province-sea-zone-detail-overlay.md` (Refs #4752).
library;

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_civilian_shortcut_control.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'map_train_civilian_copy.dart';
import 'map_train_civilian_offer.dart';

const Key kProvinceOverlayTrainExplorerKey = Key(
  'province_overlay_train_explorer',
);
const Key kProvinceOverlayTrainBuilderKey = Key(
  'province_overlay_train_builder',
);
const Key kProvinceOverlayTrainEngineerKey = Key(
  'province_overlay_train_engineer',
);
const Key kProvinceOverlayTrainMerchantKey = Key(
  'province_overlay_train_merchant',
);
const Key kProvinceOverlayTrainRailBuilderKey = Key(
  'province_overlay_train_rail_builder',
);

Key mapTrainCivilianKey(MapTrainCivilianKind kind) {
  switch (kind) {
    case MapTrainCivilianKind.explorer:
      return kProvinceOverlayTrainExplorerKey;
    case MapTrainCivilianKind.builder:
      return kProvinceOverlayTrainBuilderKey;
    case MapTrainCivilianKind.engineer:
      return kProvinceOverlayTrainEngineerKey;
    case MapTrainCivilianKind.merchant:
      return kProvinceOverlayTrainMerchantKey;
    case MapTrainCivilianKind.railBuilder:
      return kProvinceOverlayTrainRailBuilderKey;
  }
}

/// Enabled Train {type} button plus default-visible capital-after-Next-turn gist.
Widget? buildMapTrainCivilianControl({
  required AppLocalizations l10n,
  required MapTrainCivilianKind kind,
  required bool show,
  required VoidCallback? onTap,
}) {
  if (!show || onTap == null) return null;
  final label = mapTrainCivilianLabel(l10n, kind);
  final control = buildProvinceOverlayCivilianShortcutControl(
    showControl: true,
    label: label,
    tooltip: label,
    enabled: true,
    onTap: onTap,
    gist: mapTrainCivilianGist(l10n, kind),
  );
  if (control == null) return null;
  return KeyedSubtree(key: mapTrainCivilianKey(kind), child: control);
}
