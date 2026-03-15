// Full-screen Diplomacy screen. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_screen_shell.dart';
import 'diplomacy_panel.dart';

class DiplomacyScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CtScreenShell(
      title: 'Diplomacy',
      showBackButton: true,
      child: DiplomacyPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        topology: topology,
        currentOrders: currentOrders,
        onOrdersChanged: onOrdersChanged,
      ),
    );
  }
}
