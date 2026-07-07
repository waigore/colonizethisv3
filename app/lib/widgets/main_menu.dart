import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import '../config/editorial_monocle_palette.dart';
import '../config/themes.dart';
import '../config/ui_screen_ids.dart';
import 'ct_brass_divider.dart';
import 'ct_compass_rose.dart';
import 'ct_fleur_de_lis_ornament.dart';
import 'ct_gradients.dart';
import 'ct_main_menu_collage.dart';
import 'ct_nine_patch_button.dart';

part 'main_menu_constants.dart';
part 'main_menu_body.dart';
part 'main_menu_body_logo.dart';
part 'main_menu_body_content.dart';
part 'main_menu_buttons.dart';
part 'main_menu_footer.dart';
part 'main_menu_scroll_bracket.dart';

/// Visual variant of the main menu. SPEC/ui/main-menu.md; UXD 03a.
enum MainMenuVariant {
  /// Theme-scaffold only fallback: standard Flutter widgets with the
  /// running app theme; no SVG collage, no compass rose, no fleur-de-lis,
  /// no brass divider, no scroll brackets, no wood-panel chrome. See
  /// `SPEC/ui/main-menu.md` § Variant rendering.
  plain,

  /// Dark editorial-monocle layout per
  /// `SPEC/ui/mockups/SHEL10002-main-menu.html`: [CtMainMenuCollage]
  /// background, [CtCompassRose] above the title row, title flanked by two
  /// [CtFleurDeLisOrnament]s, [CtBrassDivider] between the logo region and
  /// the buttons region. Rendered under [AppThemes.editorialMonocle] and
  /// [EditorialMonoclePalette] tokens.
  pixelArt,
}

/// Content state of the main menu. SPEC/ui/main-menu.md; UXD 03a.
enum MainMenuState {
  /// Default: no subtitle; Load Game enabled if [noSaves] is not used.
  default_,

  /// After victory: show subtitle "Congratulations, you won your last game."
  afterVictory,

  /// No saves: Load Game disabled with explanatory helper text/tooltip.
  noSaves,
}

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

  bool get _loadGameEnabled => state != MainMenuState.noSaves;
  bool get _showAfterVictorySubtitle => state == MainMenuState.afterVictory;

  @override
  Widget build(BuildContext context) {
    final content = _MainMenuBody(
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
    return _PixelArtLogoRegion(title: appL10n(context).mainMenu_title);
  }
}
