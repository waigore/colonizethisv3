import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_main_menu_collage.dart';

import '../config/themes.dart';
import '../config/ui_screen_ids.dart';
import 'main_menu_body.dart';
import 'main_menu_body_logo.dart';
import 'main_menu_constants.dart';

export 'main_menu_constants.dart';

/// Main menu screen. Full-screen layout per UXD 03a wireframes.
/// Callbacks are supplied by the shell; widget does not perform routing.
/// Min 44dp touch targets per UXD 03.
class CtMainMenu extends StatelessWidget {
  const CtMainMenu({
    super.key,
    required this.variant,
    required this.state,
    required this.version,
    required this.onNewGame,
    this.resumeGameVisible = false,
    this.onResumeGame,
    required this.onLoadGame,
    required this.onSettings,
    required this.onQuit,
  }) : assert(
         !resumeGameVisible || onResumeGame != null,
         'onResumeGame is required when resumeGameVisible is true',
       );

  /// SPEC/ui/main-menu.md — [UiScreenIds.mainMenu].
  static const screenId = UiScreenIds.mainMenu;

  final MainMenuVariant variant;
  final MainMenuState state;
  final String version;
  final VoidCallback onNewGame;
  final bool resumeGameVisible;
  final VoidCallback? onResumeGame;
  final VoidCallback onLoadGame;
  final VoidCallback onSettings;
  final VoidCallback onQuit;

  bool get _loadGameEnabled => true;
  bool get _showAfterVictorySubtitle => state == MainMenuState.afterVictory;

  @override
  Widget build(BuildContext context) {
    final content = MainMenuBody(
      variant: variant,
      showAfterVictorySubtitle: _showAfterVictorySubtitle,
      loadGameEnabled: _loadGameEnabled,
      resumeGameVisible: resumeGameVisible,
      version: version,
      onNewGame: onNewGame,
      onResumeGame: onResumeGame,
      onLoadGame: onLoadGame,
      onSettings: onSettings,
      onQuit: onQuit,
      logoBuilder: _buildLogo,
    );

    if (variant == MainMenuVariant.pixelArt) {
      return Theme(
        data: AppThemes.editorialMonocle,
        child: Scaffold(
          backgroundColor: EditorialMonoclePalette.bg,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: CtMainMenuCollage()),
              content,
            ],
          ),
        ),
      );
    }

    return Scaffold(body: content);
  }

  Widget _buildLogo(BuildContext context) {
    if (variant == MainMenuVariant.plain) {
      return Text(
        appL10n(context).mainMenu_title,
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      );
    }
    return PixelArtLogoRegion(title: appL10n(context).mainMenu_title);
  }
}
