import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/package_logger.dart';
import 'tribe_first_contact_overlay_state.dart';

export 'tribe_first_contact_overlay_state.dart';

/// Blocking herald when the human GP first discovers a Tribe faction.
/// SPEC/ui/tribe-first-contact-overlay.md (OVL80001).
class TribeFirstContactOverlay extends StatefulWidget {
  const TribeFirstContactOverlay({
    super.key,
    required this.tribeName,
    required this.capitalName,
    required this.onDismissed,
    required this.child,
    this.logger,
    this.assetBundle,
  });

  static const screenId = UiScreenIds.tribeFirstContactOverlay;

  final String tribeName;
  final String capitalName;
  final VoidCallback onDismissed;
  final Widget child;
  final CtLogger? logger;
  final AssetBundle? assetBundle;

  @override
  State<TribeFirstContactOverlay> createState() =>
      TribeFirstContactOverlayState();
}
