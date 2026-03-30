import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/routes.dart';

/// Pause menu content for [OpenPauseMenuPanelEvent]. Emits bus follow-up events only.
class PauseMenuPanel extends StatelessWidget {
  const PauseMenuPanel({super.key, required this.bus});

  final AppEventBus bus;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Debug log'),
            onTap: () {
              bus.emit(const ClosePanelEvent());
              bus.emit(const NavigateToRouteEvent(Routes.debugLog));
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Resume'),
            onTap: () => bus.emit(const ClosePanelEvent()),
          ),
        ],
      ),
    );
  }
}
