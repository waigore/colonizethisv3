import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';

/// Pause menu content for [OpenPauseMenuPanelEvent]. Emits bus follow-up events only.
class PauseMenuPanel extends StatelessWidget {
  const PauseMenuPanel({super.key, required this.bus});

  static const screenId = UiScreenIds.pauseMenuPanel;

  final AppEventBus bus;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.list),
            title: Text(l10n.debugLog_title),
            onTap: () {
              bus.emit(const ClosePanelEvent());
              bus.emit(const NavigateToRouteEvent(Routes.debugLog));
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text(l10n.game_pauseMenu_resume),
            onTap: () => bus.emit(const ClosePanelEvent()),
          ),
        ],
      ),
    );
  }
}
