import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

/// Treasury-coin glyph shared with the trade screen / game tab-bar treasury chip.
const String kResearchSlotTurnPreviewTreasuryCoinAsset =
    '${kAppIconAssetPrefix}ui_icon_treasury_coin.png';

TextStyle researchSlotTurnPreviewMonoStyle(Color color) => TextStyle(
  color: color,
  fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  fontSize: 10,
);
