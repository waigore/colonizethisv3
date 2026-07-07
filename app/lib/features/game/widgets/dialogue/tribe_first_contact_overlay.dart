import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../../widgets/ct_brass_divider.dart';
import '../../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'game_start_intro_overlay.dart';
import 'ct_dialogue_view.dart';

part 'tribe_first_contact_overlay_flow.dart';
part 'tribe_first_contact_overlay_build.dart';

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
      _TribeFirstContactOverlayState();
}

class _TribeFirstContactOverlayState extends State<TribeFirstContactOverlay> {
  CtDialogueView? _view;
  DialogueRunner? _runner;
  Object? _loadError;
  bool _dialogueFinished = false;

  @override
  void initState() {
    super.initState();
    loadAndRunTribeFirstContact();
  }

  @override
  Widget build(BuildContext context) => buildTribeFirstContactOverlay(context);
}
