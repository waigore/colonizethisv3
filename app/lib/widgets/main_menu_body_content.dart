// Main-menu body content column (logo slot + buttons region). Refs #3878; #4117.

import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';

import 'main_menu_buttons.dart';
import 'main_menu_footer.dart';
import 'main_menu_scroll_bracket.dart';
import 'main_menu_variant.dart';

class MainMenuBodyContent extends StatelessWidget {
  const MainMenuBodyContent({
    required this.variant,
    required this.showAfterVictorySubtitle,
    required this.loadGameEnabled,
    required this.resumeGameVisible,
    required this.narrow,
    required this.version,
    required this.onNewGame,
    required this.onResumeGame,
    required this.onLoadGame,
    required this.onSettings,
    required this.onQuit,
    required this.logoBuilder,
  });

  final MainMenuVariant variant;
  final bool showAfterVictorySubtitle;
  final bool loadGameEnabled;
  final bool resumeGameVisible;
  final bool narrow;
  final String version;
  final VoidCallback onNewGame;
  final VoidCallback? onResumeGame;
  final VoidCallback onLoadGame;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final Widget Function(BuildContext context) logoBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: _menuChildren(context),
    );
  }

  List<Widget> _menuChildren(BuildContext context) {
    final l10n = appL10n(context);
    final bool isPixelArt = variant == MainMenuVariant.pixelArt;
    final TextStyle? subtitleStyle = isPixelArt
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: EditorialMonoclePalette.muted,
          )
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic);
    return [
      const SizedBox(height: 48),
      logoBuilder(context),
      if (showAfterVictorySubtitle) ...[
        const SizedBox(height: 12),
        Text(
          l10n.mainMenu_subtitleAfterVictory,
          style: subtitleStyle,
          textAlign: TextAlign.center,
        ),
      ],
      if (isPixelArt) ...[
        const SizedBox(height: 24),
        const CtBrassDivider(),
        const SizedBox(height: 24),
      ] else
        const SizedBox(height: 32),
      _buttonsRegion(context),
      const SizedBox(height: 32),
      MainMenuFooter(
        variant: variant,
        version: version,
        quitLabel: l10n.mainMenu_quit,
        onQuit: onQuit,
      ),
      const SizedBox(height: 24),
    ];
  }

  /// Builds the buttons region (New Game → Settings) for the active variant.
  ///
  /// In the `pixelArt` variant the column of wood-panel buttons is wrapped in
  /// a [MainMenuPixelArtButtonsRegion] so left/right ornamental scroll brackets
  /// can flank the panel at `kMainMenuScrollBracketGutter` outside each edge,
  /// painted across the middle `1 - 2 * kMainMenuScrollBracketVerticalInset`
  /// fraction of the region height (`SPEC/ui/main-menu.md` § Buttons region;
  /// mockup `.buttons-region::before` / `::after`). In the `plain` variant
  /// the buttons render as a plain `Column` with no scroll-bracket chrome
  /// per the Variant rendering table.
  Widget _buttonsRegion(BuildContext context) {
    final l10n = appL10n(context);
    final List<Widget> buttons = <Widget>[
      MainMenuButton(
        label: l10n.mainMenu_newGame,
        variant: variant,
        narrow: narrow,
        onPressed: onNewGame,
      ),
      if (resumeGameVisible) ...[
        const SizedBox(height: 12),
        MainMenuButton(
          label: l10n.mainMenu_resumeGame,
          variant: variant,
          narrow: narrow,
          onPressed: onResumeGame!,
        ),
      ],
      const SizedBox(height: 12),
      MainMenuLoadGameButton(
        enabled: loadGameEnabled,
        variant: variant,
        narrow: narrow,
        onPressed: onLoadGame,
      ),
      const SizedBox(height: 12),
      MainMenuButton(
        label: l10n.mainMenu_settings,
        variant: variant,
        narrow: narrow,
        onPressed: onSettings,
      ),
    ];
    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
    if (variant == MainMenuVariant.pixelArt) {
      return MainMenuPixelArtButtonsRegion(child: column);
    }
    return column;
  }
}
