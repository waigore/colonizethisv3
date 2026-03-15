// Full-screen Production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_screen_shell.dart';
import 'production_panel.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({
    super.key,
    required this.game,
    required this.player,
    required this.desiredOutputByRecipe,
    required this.onDesiredOutputChanged,
  });

  final Game game;
  final Player player;
  final Map<String, int> desiredOutputByRecipe;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;

  @override
  Widget build(BuildContext context) {
    return CtScreenShell(
      title: 'Production',
      showBackButton: true,
      child: ProductionPanel(
        game: game,
        player: player,
        desiredOutputByRecipe: desiredOutputByRecipe,
        onDesiredOutputChanged: onDesiredOutputChanged,
      ),
    );
  }
}
