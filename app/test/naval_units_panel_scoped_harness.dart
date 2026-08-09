// Stateful host for location-scope / draft-move naval panel pins (Refs #4224).
library;

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';

import 'app_shell_harness.dart';

/// Stateful host for location-scope / draft-move naval panel pins.
class ScopedNavalPanelHarness extends StatefulWidget {
  const ScopedNavalPanelHarness({
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.locationScopeKey,
    this.removeFleetOnNextFrame = false,
    super.key,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;
  final String? locationScopeKey;
  final bool removeFleetOnNextFrame;

  @override
  State<ScopedNavalPanelHarness> createState() =>
      _ScopedNavalPanelHarnessState();
}

class _ScopedNavalPanelHarnessState extends State<ScopedNavalPanelHarness> {
  late Orders _draftOrders;
  late Game _game;
  StreamSubscription<NavalMoveFleetRequestedEvent>? _moveSub;

  @override
  void initState() {
    super.initState();
    _draftOrders = const Orders();
    _game = widget.game;
    _moveSub = widget.bus.on<NavalMoveFleetRequestedEvent>().listen((event) {
      if (!mounted) return;
      setState(() {
        _draftOrders = Orders(
          navalMoveOrdersByPlayerId: {
            event.humanPlayerId: [
              NavalMoveOrder(
                fleetId: event.moveOrder.fleetId,
                destinationSeaZoneId: event.moveOrder.destinationSeaZoneId,
                destinationPortProvinceId:
                    event.moveOrder.destinationPortProvinceId,
              ),
            ],
          },
        );
      });
    });
    if (widget.removeFleetOnNextFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _game = _game.copyWith(
            worldState: _game.worldState.copyWith(fleets: const []),
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _moveSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildAppShell(
      child: Scaffold(
        body: NavalUnitsPanel(
          game: _game,
          humanPlayerId: widget.humanPlayerId,
          bus: widget.bus,
          topology: widget.topology,
          draftOrders: _draftOrders,
          locationScopeKey: widget.locationScopeKey,
        ),
      ),
    );
  }
}
