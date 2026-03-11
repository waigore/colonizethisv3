// Full-screen Technology view with Slots and Tech Tree tabs. SPEC/ui/tech-tree-widget.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'technology_panel.dart';
import 'tech_tree_widget.dart';

/// Full-screen Technology screen with two tabs: Research Slots and Tech Tree.
/// SPEC/ui/tech-tree-widget.md.
class TechnologyScreen extends StatelessWidget {
  const TechnologyScreen({
    super.key,
    required this.game,
    required this.player,
  });

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Technology'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Slots', icon: Icon(Icons.list_alt)),
              Tab(text: 'Tree', icon: Icon(Icons.account_tree)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SlotsTab(game: game, player: player),
            _TreeTab(game: game, player: player),
          ],
        ),
      ),
    );
  }
}

class _SlotsTab extends StatelessWidget {
  const _SlotsTab({required this.game, required this.player});

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TechnologyPanel(game: game, player: player),
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
