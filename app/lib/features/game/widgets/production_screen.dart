// Full-screen Production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/production_allocation_provider.dart';
import '../../../widgets/ct_screen_shell.dart';
import 'production_panel.dart';

class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({
    super.key,
    required this.game,
    required this.player,
  });

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);

    return CtScreenShell(
      title: 'Production',
      showBackButton: true,
      child: ProductionPanel(
        game: game,
        player: player,
        desiredOutputByRecipe: desiredOutputByRecipe,
        onDesiredOutputChanged: (next) {
          ref.read(productionDesiredOutputProvider.notifier).state = next;
        },
      ),
    );
  }
}
