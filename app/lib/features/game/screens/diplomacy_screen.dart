// Full-screen Diplomacy screen. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_event_bus_provider.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../shell_player_context.dart' show shellPanelsNotDefined, shellPlayerContextProvider;
import '../widgets/observe_mode_not_defined_panel.dart';
import '../widgets/diplomacy_panel.dart';
import '../widgets/grant_or_subsidy_listener.dart';

class DiplomacyScreen extends ConsumerWidget {
  const DiplomacyScreen({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bus = ref.watch(appEventBusProvider);
    return CtGameFeatureScreenShell(
      game: game,
      title: 'Diplomacy',
      bodyBuilder: (context, shellRef, displayGame) {
        if (shellPanelsNotDefined(shellRef)) {
          return const ObserveModeNotDefinedPanel(title: 'Diplomacy');
        }
        final orders = shellRef.watch(currentOrdersProvider);
        MapTopology topology = const MapTopology();
        try {
          final gameService = shellRef.watch(gameServiceProvider);
          final loaded = gameService.getMapData(displayGame.id);
          if (loaded != null) {
            topology = loaded.combinedTopology;
          }
        } on Object {
          // Widget tests may not initialize Hive-backed game service providers.
        }
        final readOnly =
            !shellRef.read(shellPlayerContextProvider).canMutateViaUi;
        return GrantOrSubsidyListener(
          bus: bus,
          game: displayGame,
          humanPlayerId: humanPlayerId,
          readOnly: readOnly,
          child: DiplomacyPanel(
            game: displayGame,
            humanPlayerId: humanPlayerId,
            topology: topology,
            currentOrders: orders,
            bus: bus,
            readOnly: readOnly,
          ),
        );
      },
    );
  }
}
