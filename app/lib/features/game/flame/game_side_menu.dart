import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;

import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';
import '../widgets/civilian_units_panel.dart';
import '../widgets/diplomacy_screen.dart';
import '../widgets/military_units_panel.dart';
import '../widgets/naval_units_panel.dart';
import '../widgets/production_screen.dart';
import '../widgets/technology_screen.dart';

import 'game_screen_shared.dart';

/// Side menu ("Production", "Units", etc.) for the in-game shell.
class GameSideMenu extends ConsumerWidget {
  const GameSideMenu({
    required this.game,
    required this.humanPlayerId,
    required this.sideMenuOpen,
    required this.onClose,
    required this.onLocateCivilianUnit,
    required this.onLocateMilitaryTile,
    required this.onLocateNavalFleet,
    required this.onCancelUnitWork,
    required this.onStartWorkTargetSelection,
    super.key,
  });

  final ct_models.Game game;
  final String humanPlayerId;
  final bool sideMenuOpen;
  final VoidCallback onClose;

  final void Function(ct_models.Unit unit) onLocateCivilianUnit;
  final void Function(String tileKey, String regionId) onLocateMilitaryTile;
  final void Function(String tileKey, String regionId) onLocateNavalFleet;
  final void Function(String unitId) onCancelUnitWork;
  final void Function(ct_models.Unit unit, String workTarget)
  onStartWorkTargetSelection;

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
            Image.asset(iconAsset, width: 20, height: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmpireMenuButtons(BuildContext context, WidgetRef ref) {
    final player =
        game.players.where((p) => p.isHuman).firstOrNull ?? game.players.first;
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? MapTopology();

    return [
      _empireButton(
        context,
        iconAsset: 'assets/images/ui_icon_production.png',
        label: 'Production',
        onPressed: () {
          onClose();
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (ctx) => ProductionScreen(game: game, player: player),
            ),
          );
        },
      ),
      _empireButton(
        context,
        iconAsset: 'assets/images/ui_icon_civilian_units.png',
        label: 'Civilian Units',
        onPressed: () {
          onClose();
          // Capture values before showing bottom sheet to avoid using
          // disposed ref when widget rebuilds during work target selection.
          final currentGame = ref.read(currentGameProvider) ?? game;
          final currentOrders = ref.read(currentOrdersProvider);
          final availableWorkTargets = ref.read(availableWorkTargetsProvider);
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (ctx) {
              final isNarrowCtx =
                  MediaQuery.sizeOf(ctx).width < kInGameNarrowBreakpoint;
              final maxHeight =
                  MediaQuery.sizeOf(ctx).height * (isNarrowCtx ? 0.33 : 0.5);
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: CivilianUnitsPanel(
                  game: currentGame,
                  humanPlayerId: humanPlayerId,
                  currentOrders: currentOrders,
                  availableWorkTargets: availableWorkTargets,
                  onLocateUnit: onLocateCivilianUnit,
                  onRemoveWorkOrder: (playerId, index) {
                    final o = currentOrders;
                    final list = List<ct_models.WorkOrder>.from(
                      o.workOrdersByPlayerId[playerId] ?? [],
                    )..removeAt(index);
                    ref.read(currentOrdersProvider.notifier).state = o.copyWith(
                      workOrdersByPlayerId: {
                        ...o.workOrdersByPlayerId,
                        playerId: list,
                      },
                    );
                  },
                  onCancelUnitWork: onCancelUnitWork,
                  onStartWorkTargetSelection: (unit, workTarget) {
                    Navigator.of(ctx).pop();
                    onStartWorkTargetSelection(unit, workTarget);
                  },
                ),
              );
            },
          );
        },
      ),
      _empireButton(
        context,
        iconAsset: 'assets/images/ui_icon_military_units.png',
        label: 'Military Units',
        onPressed: () {
          onClose();
          showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => MilitaryUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              onLocateTile: onLocateMilitaryTile,
            ),
          );
        },
      ),
      _empireButton(
        context,
        iconAsset: 'assets/images/ui_icon_naval_units.png',
        label: 'Naval Units',
        onPressed: () {
          onClose();
          showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => NavalUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              onLocateFleet: onLocateNavalFleet,
            ),
          );
        },
      ),
      _empireButton(
        context,
        iconAsset: 'assets/images/ui_icon_diplomacy.png',
        label: 'Diplomacy',
        onPressed: () {
          onClose();
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => DiplomacyScreen(
                game: game,
                humanPlayerId: humanPlayerId,
                topology: topology,
                currentOrders: orders,
                onOrdersChanged: (newOrders) {
                  ref.read(currentOrdersProvider.notifier).state = newOrders;
                },
              ),
            ),
          );
        },
      ),
      _empireButton(
        context,
        iconAsset: 'assets/images/ui_icon_technology.png',
        label: 'Technology',
        onPressed: () {
          onClose();
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (ctx) => TechnologyScreen(
                game: game,
                player: player,
                currentOrders: orders,
                onOrdersChanged: (newOrders) {
                  ref.read(currentOrdersProvider.notifier).state = newOrders;
                },
              ),
            ),
          );
        },
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CtNinePatchButton(
          onPressed: () {
            onClose();
            Navigator.of(context).pushNamed(Routes.debugLog);
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CtNinePatchButton(onPressed: onClose, child: const Text('×')),
                ],
              ),
              const SizedBox(height: 8),
              ..._buildEmpireMenuButtons(context, ref),
            ],
          ),
        ),
      ),
    );
  }
}
