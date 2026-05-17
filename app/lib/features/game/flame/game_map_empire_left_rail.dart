import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_assets.dart';
import '../../../config/routes.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../providers/debug_console_provider.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'game_screen_shared.dart';

/// Always-visible icon column for empire actions on the in-game map.
/// SPEC/ui/empire-overview.md, empire-buttons.md.
class GameMapEmpireLeftRail extends ConsumerWidget {
  const GameMapEmpireLeftRail({
    required this.game,
    required this.humanPlayerId,
    this.onIconTappedWhileSelectionMode,
    super.key,
  });

  final ct_models.Game game;
  final String humanPlayerId;
  final VoidCallback? onIconTappedWhileSelectionMode;

  Widget _iconTile({
    required Key buttonKey,
    required String tooltip,
    required String iconAsset,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: Material(
            key: buttonKey,
            color: Colors.white.withValues(alpha: 0.9),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: StrictAssetIcon(
                  assetPath: iconAsset,
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? MapTopology();
    final bus = ref.read(appEventBusProvider);
    final debugConsoleEnabled = ref.watch(debugConsoleEnabledProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconTile(
            buttonKey: kEmpireProductionButtonKey,
            tooltip: 'Production',
            iconAsset: '${kAppIconAssetPrefix}ui_icon_production.png',
            onTap: () {
              onIconTappedWhileSelectionMode?.call();
              bus.emit(
                ct_models.NavigateToRouteEvent(Routes.production, {
                  'game': game,
                  'humanPlayerId': humanPlayerId,
                }),
              );
            },
          ),
          _iconTile(
            buttonKey: kEmpireCivilianUnitsButtonKey,
            tooltip: 'Civilian Units',
            iconAsset: '${kAppIconAssetPrefix}ui_icon_civilian_units.png',
            onTap: () {
              onIconTappedWhileSelectionMode?.call();
              bus.emit(const ct_models.OpenCivilianUnitsPanelEvent());
            },
          ),
          _iconTile(
            buttonKey: kEmpireMilitaryUnitsButtonKey,
            tooltip: 'Military Units',
            iconAsset: '${kAppIconAssetPrefix}ui_icon_military_units.png',
            onTap: () {
              onIconTappedWhileSelectionMode?.call();
              bus.emit(const ct_models.OpenMilitaryUnitsPanelEvent());
            },
          ),
          _iconTile(
            buttonKey: kEmpireNavalUnitsButtonKey,
            tooltip: 'Naval Units',
            iconAsset: '${kAppIconAssetPrefix}ui_icon_naval_units.png',
            onTap: () {
              onIconTappedWhileSelectionMode?.call();
              bus.emit(const ct_models.OpenNavalUnitsPanelEvent());
            },
          ),
          _iconTile(
            buttonKey: kEmpireDiplomacyButtonKey,
            tooltip: 'Diplomacy',
            iconAsset: '${kAppIconAssetPrefix}ui_icon_diplomacy.png',
            onTap: () {
              onIconTappedWhileSelectionMode?.call();
              bus.emit(
                ct_models.NavigateToRouteEvent(Routes.diplomacy, {
                  'game': game,
                  'humanPlayerId': humanPlayerId,
                  'topology': topology,
                  'currentOrders': orders,
                }),
              );
            },
          ),
          _iconTile(
            buttonKey: kEmpireTechnologyButtonKey,
            tooltip: 'Technology',
            iconAsset: '${kAppIconAssetPrefix}ui_icon_technology.png',
            onTap: () {
              onIconTappedWhileSelectionMode?.call();
              bus.emit(
                ct_models.NavigateToRouteEvent(Routes.technology, {
                  'game': game,
                  'humanPlayerId': humanPlayerId,
                  'currentOrders': orders,
                }),
              );
            },
          ),
          if (debugConsoleEnabled)
            _iconTile(
              buttonKey: kEmpireDebugConsoleButtonKey,
              tooltip: 'Debug Console',
              iconAsset: '${kAppIconAssetPrefix}ui_icon_layer_toggle.png',
              onTap: () {
                onIconTappedWhileSelectionMode?.call();
                bus.emit(const ct_models.ToggleDebugConsolePanelEvent());
              },
            ),
        ],
      ),
    );
  }
}
