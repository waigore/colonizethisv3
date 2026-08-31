import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/technology_panel_session_cache_provider.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../widgets/technology/tech_tree_widget.dart';
import '../../widgets/technology/technology_panel.dart';

/// Slots and Tree tab bodies for [TechnologyScreen] (Refs #4117 de-part).
class TechnologySlotsBody extends ConsumerWidget {
  const TechnologySlotsBody({
    super.key,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final openPath = ref.watch(technologyPanelSlotsOpenPathProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: TechnologyPanel(
        game: game,
        player: player,
        currentOrders: currentOrders,
        onOrdersChanged: onOrdersChanged,
        slotsOpenPath: openPath,
      ),
    );
  }
}

class TechnologyTreeBody extends StatelessWidget {
  const TechnologyTreeBody({
    super.key,
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
    return TechTreeWidget(
      game: game,
      player: player,
      currentOrders: currentOrders,
      onOrdersChanged: onOrdersChanged,
    );
  }
}
