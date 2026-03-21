import 'package:flutter/material.dart';

/// Pause menu content for [OpenPanelEvent] id `pause_menu`.
/// Params: `onDebugLog`, `onResume` as [VoidCallback] (typically emit bus events).
class PauseMenuPanel extends StatelessWidget {
  const PauseMenuPanel({super.key, required this.params});

  final Map<String, Object?>? params;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Debug log'),
            onTap: () => (params?['onDebugLog'] as VoidCallback?)?.call(),
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Resume'),
            onTap: () => (params?['onResume'] as VoidCallback?)?.call(),
          ),
        ],
      ),
    );
  }
}
