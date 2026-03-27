// Full-screen Diplomacy screen. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_event_bus_provider.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import 'diplomacy_panel.dart';
import 'grant_or_subsidy_listener.dart';

class DiplomacyScreen extends ConsumerWidget {
  const DiplomacyScreen({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.topology,
    required this.onOrdersChanged,
    this.currentOrders = const Orders(),
  });

  final Game game;
  final String humanPlayerId;
  final MapTopology topology;
  final Orders currentOrders;
  final void Function(Orders orders) onOrdersChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bus = ref.watch(appEventBusProvider);
    return CtGameFeatureScreenShell(
      game: game,
      title: 'Diplomacy',
      bodyBuilder: (context, shellRef, displayGame) {
        return GrantOrSubsidyListener(
          bus: bus,
          game: displayGame,
          onConfirmed: (order) {
            final list = List<DiplomaticOrder>.from(
              currentOrders.diplomaticOrdersByPlayerId[humanPlayerId] ?? [],
            )..add(order);
            onOrdersChanged(
              currentOrders.copyWith(
                diplomaticOrdersByPlayerId: {
                  ...currentOrders.diplomaticOrdersByPlayerId,
                  humanPlayerId: list,
                },
              ),
            );
          },
          child: DiplomacyPanel(
            game: displayGame,
            humanPlayerId: humanPlayerId,
            topology: topology,
            currentOrders: currentOrders,
            onOrdersChanged: onOrdersChanged,
            bus: bus,
          ),
        );
      },
    );
  }
}
