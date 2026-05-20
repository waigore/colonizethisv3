// Full-screen Technology view with Slots and Tech Tree tabs. SPEC/ui/tech-tree-widget.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/games_provider.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../shell_player_context.dart';
import '../widgets/observe_mode_not_defined_panel.dart';
import '../widgets/tech_tree_widget.dart';
import '../widgets/technology_panel.dart';

/// Full-screen Technology screen with two tabs: Research Slots and Tech Tree.
/// SPEC/ui/tech-tree-widget.md.
class TechnologyScreen extends ConsumerWidget {
  const TechnologyScreen({super.key, required this.game, required this.player});

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrders = ref.watch(currentOrdersProvider);
    return CtGameFeatureScreenShell(
      game: game,
      title: 'Technology',
      bodyBuilder: (context, shellRef, displayGame) {
        if (shellPanelsNotDefined(shellRef)) {
          return const ObserveModeNotDefinedPanel(title: 'Technology');
        }
        final displayPlayer = displayGame.playerById(player.id)!;
        final canEdit = shellRef.read(shellPlayerContextProvider).canMutateViaUi;
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Slots'),
                  Tab(text: 'Tree'),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  children: [
                    _SlotsTab(
                      game: displayGame,
                      player: displayPlayer,
                      currentOrders: currentOrders,
                      onOrdersChanged: canEdit
                          ? (next) {
                              shellRef
                                  .read(currentOrdersProvider.notifier)
                                  .replaceAll(next);
                            }
                          : null,
                    ),
                    _TreeTab(game: displayGame, player: displayPlayer),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SlotsTab extends StatelessWidget {
  const _SlotsTab({
    required this.game,
    required this.player,
    this.currentOrders = const Orders(),
    this.onOrdersChanged,
  });

  final Game game;
  final Player player;
  final Orders currentOrders;
  final void Function(Orders orders)? onOrdersChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TechnologyPanel(
        game: game,
        player: player,
        currentOrders: currentOrders,
        onOrdersChanged: onOrdersChanged,
      ),
    );
  }
}

class _TreeTab extends StatelessWidget {
  const _TreeTab({required this.game, required this.player});

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return TechTreeWidget(game: game, player: player);
  }
}
