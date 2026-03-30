import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_assets.dart';
import '../../../config/routes.dart';
import '../../../providers/app_event_bus_provider.dart';

import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/strict_asset_icon.dart';

/// Side menu ("Production", "Units", etc.) for the in-game shell.
class GameSideMenu extends ConsumerWidget {
  const GameSideMenu({
    required this.game,
    required this.humanPlayerId,
    required this.sideMenuOpen,
    required this.onClose,
    super.key,
  });

  final ct_models.Game game;
  final String humanPlayerId;
  final bool sideMenuOpen;
  final VoidCallback onClose;

  static const double _kSideMenuWidth = 280;

  Widget _empireButton(
    BuildContext context, {
    required String iconAsset,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CtNinePatchButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StrictAssetIcon(assetPath: iconAsset, width: 20, height: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmpireMenuButtons(BuildContext context, WidgetRef ref) {
    final bus = ref.read(appEventBusProvider);

    return [
      _empireButton(
        context,
        iconAsset: '${kAppIconAssetPrefix}ui_icon_production.png',
        label: 'Production',
        onPressed: () {
          onClose();
          bus.emit(
            ct_models.NavigateToRouteEvent(Routes.production, {
              'game': game,
              'humanPlayerId': humanPlayerId,
            }),
          );
        },
      ),
      _empireButton(
        context,
        iconAsset: '${kAppIconAssetPrefix}ui_icon_civilian_units.png',
        label: 'Civilian Units',
        onPressed: () {
          onClose();
          bus.emit(const ct_models.OpenCivilianUnitsPanelEvent());
        },
      ),
      _empireButton(
        context,
        iconAsset: '${kAppIconAssetPrefix}ui_icon_military_units.png',
        label: 'Military Units',
        onPressed: () {
          onClose();
          bus.emit(const ct_models.OpenMilitaryUnitsPanelEvent());
        },
      ),
      _empireButton(
        context,
        iconAsset: '${kAppIconAssetPrefix}ui_icon_naval_units.png',
        label: 'Naval Units',
        onPressed: () {
          onClose();
          bus.emit(const ct_models.OpenNavalUnitsPanelEvent());
        },
      ),
      _empireButton(
        context,
        iconAsset: '${kAppIconAssetPrefix}ui_icon_diplomacy.png',
        label: 'Diplomacy',
        onPressed: () {
          onClose();
          ref
              .read(appEventBusProvider)
              .emit(
                ct_models.NavigateToRouteEvent(Routes.diplomacy, {
                  'game': game,
                  'humanPlayerId': humanPlayerId,
                }),
              );
        },
      ),
      _empireButton(
        context,
        iconAsset: '${kAppIconAssetPrefix}ui_icon_technology.png',
        label: 'Technology',
        onPressed: () {
          onClose();
          ref
              .read(appEventBusProvider)
              .emit(
                ct_models.NavigateToRouteEvent(Routes.technology, {
                  'game': game,
                  'humanPlayerId': humanPlayerId,
                }),
              );
        },
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CtNinePatchButton(
          onPressed: () {
            onClose();
            ref
                .read(appEventBusProvider)
                .emit(const ct_models.NavigateToRouteEvent(Routes.debugLog));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bug_report, size: 20),
              const SizedBox(width: 8),
              const Text('Debug log'),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // When more menu items are present (e.g. Debug log), the panel must
              // remain within the available height; make the list scrollable.
              Expanded(
                child: ListView(
                  children: _buildEmpireMenuButtons(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
