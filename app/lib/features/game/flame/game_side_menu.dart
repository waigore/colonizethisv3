import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/routes.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';

/// Slide-out menu for **Debug log** only (hamburger). Empire actions use [GameMapEmpireLeftRail].
/// SPEC/ui/in-game-shell-narrow.md, empire-overview.md.
class GameSideMenu extends ConsumerWidget {
  const GameSideMenu({
    required this.sideMenuOpen,
    required this.onClose,
    super.key,
  });

  final bool sideMenuOpen;
  final VoidCallback onClose;

  static const double _kSideMenuWidth = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = appL10n(context);
    return TweenAnimationBuilder<Offset>(
      key: ValueKey(sideMenuOpen),
      tween: Tween<Offset>(
        begin: Offset(sideMenuOpen ? -1 : 0, 0),
        end: Offset(sideMenuOpen ? 0 : -1, 0),
      ),
      duration: const Duration(milliseconds: 200),
      builder: (context, Offset offset, child) {
        return Positioned(
          left: offset.dx * _kSideMenuWidth,
          top: 0,
          bottom: 0,
          width: _kSideMenuWidth,
          child: child!,
        );
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < -5) onClose();
        },
        child: CtPanel(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CtNinePatchButton(onPressed: onClose, child: const Text('×')),
                ],
              ),
              const SizedBox(height: 8),
              CtNinePatchButton(
                onPressed: () {
                  onClose();
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        const ct_models.NavigateToRouteEvent(Routes.debugLog),
                      );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bug_report, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.debugLog_title),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
