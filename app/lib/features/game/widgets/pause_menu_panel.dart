import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_brass_divider.dart';
import '../../../widgets/ct_dialog_shell.dart';
import 'chrome/ct_nine_patch_button.dart';

/// Pause menu modal for [OpenPauseMenuPanelEvent]. Emits bus events only.
///
/// SPEC: `SPEC/ui/pause-menu-panel.md` (5-button modal contract, issue
/// #2867 § R1, R30). Visual structure: `CtDialogShell` frame, "Game Paused"
/// title in `--accent`, `CtBrassDivider`, then five `CtNinePatchButton`
/// rows in fixed order — Resume, Save Game (disabled), Load Game
/// (disabled), Settings (disabled), Exit to Main Menu (danger variant).
class PauseMenuPanel extends StatelessWidget {
  const PauseMenuPanel({super.key, required this.bus});

  static const screenId = UiScreenIds.pauseMenuPanel;

  /// Key for the Resume action `CtNinePatchButton`.
  static const Key resumeButtonKey = ValueKey<String>(
    'pauseMenuPanel.resumeButton',
  );

  /// Key for the Save Game action (disabled placeholder).
  static const Key saveGameButtonKey = ValueKey<String>(
    'pauseMenuPanel.saveGameButton',
  );

  /// Key for the Load Game action (disabled placeholder).
  static const Key loadGameButtonKey = ValueKey<String>(
    'pauseMenuPanel.loadGameButton',
  );

  /// Key for the Settings action (disabled placeholder).
  static const Key settingsButtonKey = ValueKey<String>(
    'pauseMenuPanel.settingsButton',
  );

  /// Key for the destructive Exit to Main Menu action.
  static const Key exitToMainMenuButtonKey = ValueKey<String>(
    'pauseMenuPanel.exitToMainMenuButton',
  );

  /// Key for the brass divider that separates the title from the action
  /// stack.
  static const Key brassDividerKey = ValueKey<String>(
    'pauseMenuPanel.brassDivider',
  );

  /// Key for the title `Text` widget.
  static const Key titleKey = ValueKey<String>('pauseMenuPanel.title');

  final AppEventBus bus;

  void _onResumeTap() {
    bus.emit(const ClosePanelEvent());
  }

  void _onExitToMainMenuTap() {
    bus.emit(const ClosePanelEvent());
    bus.emit(const RequestExitToMainMenuFlowEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      maxWidth: 360,
      maxHeight: 480,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.game_pauseMenu_title,
            key: titleKey,
            textAlign: TextAlign.center,
            style: _titleStyle(theme),
          ),
          const SizedBox(height: 12),
          const Padding(
            key: brassDividerKey,
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: CtBrassDivider(),
          ),
          const SizedBox(height: 16),
          ..._actionRows(l10n),
        ],
      ),
    );
  }

  TextStyle? _titleStyle(ThemeData theme) =>
      theme.textTheme.titleMedium?.copyWith(
        color: EditorialMonoclePalette.accent,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  List<Widget> _actionRows(AppLocalizations l10n) => <Widget>[
    CtNinePatchButton(
      key: resumeButtonKey,
      onPressed: _onResumeTap,
      child: Text(l10n.game_pauseMenu_resume),
    ),
    const SizedBox(height: 8),
    CtNinePatchButton(
      key: saveGameButtonKey,
      onPressed: null,
      enabled: false,
      child: Text(l10n.game_pauseMenu_saveGame),
    ),
    const SizedBox(height: 8),
    CtNinePatchButton(
      key: loadGameButtonKey,
      onPressed: null,
      enabled: false,
      child: Text(l10n.game_pauseMenu_loadGame),
    ),
    const SizedBox(height: 8),
    CtNinePatchButton(
      key: settingsButtonKey,
      onPressed: null,
      enabled: false,
      child: Text(l10n.game_pauseMenu_settings),
    ),
    const SizedBox(height: 8),
    CtNinePatchButton(
      key: exitToMainMenuButtonKey,
      dangerVariant: true,
      onPressed: _onExitToMainMenuTap,
      child: Text(
        l10n.game_pauseMenu_exitToMainMenu,
        style: TextStyle(color: EditorialMonoclePalette.danger),
      ),
    ),
  ];
}
