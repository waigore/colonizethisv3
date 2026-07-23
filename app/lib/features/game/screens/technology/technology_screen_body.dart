// Slots and Tree tab bodies for [TechnologyScreen].

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import '../../widgets/technology/tech_tree_widget.dart';
import '../../widgets/technology/technology_panel.dart';

class TechnologyScreenSlotsBody extends StatelessWidget {
  const TechnologyScreenSlotsBody({
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: TechnologyPanel(
        game: game,
        player: player,
        currentOrders: currentOrders,
        onOrdersChanged: onOrdersChanged,
      ),
    );
  }
}

class TechnologyScreenTreeBody extends StatelessWidget {
  const TechnologyScreenTreeBody({
    super.key,
    required this.game,
    required this.player,
  });

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return TechTreeWidget(game: game, player: player);
  }
}
