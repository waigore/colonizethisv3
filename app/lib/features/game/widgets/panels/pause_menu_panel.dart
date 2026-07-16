import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

/// Pause menu modal for [OpenPauseMenuPanelEvent]. Emits bus events only.
///
/// SPEC: `SPEC/ui/pause-menu-panel.md`. Save/Load open dialogs when not
/// turn-resolution-blocking; Settings remains a disabled placeholder.
class PauseMenuPanel extends ConsumerWidget {
  const PauseMenuPanel({super.key, required this.bus});

  static const screenId = UiScreenIds.pauseMenuPanel;

  /// Key for the Resume action `CtNinePatchButton`.
  static const Key resumeButtonKey = ValueKey<String>(
    'pauseMenuPanel.resumeButton',
  );

  /// Key for the Save Game action.
  static const Key saveGameButtonKey = ValueKey<String>(
    'pauseMenuPanel.saveGameButton',
  );

  /// Key for the Load Game action.
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

  void _onSaveTap() {
    bus.emit(const OpenDialogEvent(saveGameNameDialogId));
  }

  void _onLoadTap() {
    bus.emit(
      const OpenDialogEvent(loadGameListDialogId, {'fromPause': true}),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final saveLoadEnabled = !ref.watch(turnResolutionBlockingProvider);
    return CtDialogShell(
      maxWidth: 360,
      maxHeight: 480,
      padding: const EdgeInsets.all(CtSpacing.l),
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
          CtGap.ml,
          const Padding(
            key: brassDividerKey,
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: CtBrassDivider(),
          ),
          CtGap.l,
          ..._actionRows(l10n, saveLoadEnabled: saveLoadEnabled),
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

  List<Widget> _actionRows(
    AppLocalizations l10n, {
    required bool saveLoadEnabled,
  }) =>
      <Widget>[
        CtNinePatchButton(
          key: resumeButtonKey,
          onPressed: _onResumeTap,
          child: Text(l10n.game_pauseMenu_resume),
        ),
        CtGap.m,
        CtNinePatchButton(
          key: saveGameButtonKey,
          onPressed: saveLoadEnabled ? _onSaveTap : null,
          enabled: saveLoadEnabled,
          child: Text(l10n.game_pauseMenu_saveGame),
        ),
        CtGap.m,
        CtNinePatchButton(
          key: loadGameButtonKey,
          onPressed: saveLoadEnabled ? _onLoadTap : null,
          enabled: saveLoadEnabled,
          child: Text(l10n.game_pauseMenu_loadGame),
        ),
        CtGap.m,
        CtNinePatchButton(
          key: settingsButtonKey,
          onPressed: null,
          enabled: false,
          child: Text(l10n.game_pauseMenu_settings),
        ),
        CtGap.m,
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
