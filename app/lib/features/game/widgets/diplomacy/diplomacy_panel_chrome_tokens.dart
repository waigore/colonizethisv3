// Shared badge overlay tokens for diplomacy panel chrome.
// SPEC/ui/diplomacy-panel.md § Relation state badge, § Formal alliance indicator.

import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'diplomacy_panel_constants.dart';

/// Translucent overlay used as the WAR-state badge background.
final Color diplomacyWarBadgeBackground = oklchToColor(
  const OklchToken(0.40, 0.06, 20),
).withValues(alpha: 0.4);

/// Translucent overlay used as the PEACE-state badge background.
final Color diplomacyPeaceBadgeBackground = oklchToColor(
  const OklchToken(0.40, 0.06, 150),
).withValues(alpha: 0.2);

/// Translucent overlay used as the formal-alliance badge background.
final Color diplomacyAllianceBadgeBackground = oklchToColor(
  kDiplomacyAllianceBadgeBgToken,
).withValues(alpha: kDiplomacyAllianceBadgeAlpha);
