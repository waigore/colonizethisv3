import 'package:flutter/material.dart';

import 'ct_top_bar.dart';
import 'strict_asset_icon.dart';

/// Shared Map-back + icon + title contract for game feature screens
/// (Diplomacy / Production / Technology / Trade). Refs #3952.
///
/// Screen widgets keep their own `topBarKey` / title / icon asset constants
/// (tests and SPEC pin those literals); they build chrome through this helper
/// so the `CtTopBar` + 18×18 [StrictAssetIcon] wiring stays in one place.
class GameFeatureScreenTopBar {
  GameFeatureScreenTopBar._();

  /// Localized back-button label after the chevron. SPEC requires the literal
  /// `"Map"` so the affordance reads `"← Map"` on every feature screen.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String backLabel = 'Map';

  /// Icon edge length shared by Diplomacy / Production / Technology / Trade.
  static const double iconSize = 18;

  /// Builds the dark-theme feature-screen [CtTopBar].
  static CtTopBar build({
    required Key key,
    required String title,
    required String iconAsset,
    Widget? trailing,
  }) {
    return CtTopBar(
      key: key,
      title: title,
      backButtonLabel: backLabel,
      icon: StrictAssetIcon(
        assetPath: iconAsset,
        width: iconSize,
        height: iconSize,
      ),
      trailing: trailing,
    );
  }
}
