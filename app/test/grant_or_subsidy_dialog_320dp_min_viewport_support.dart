// Shared GrantOrSubsidyDialog 320 dp fixture (Refs #4720 Slice G).
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'dialogs_320dp_min_viewport_support.dart';

/// Minimum supported viewport — family SoT Size(320, 640).
const Size kGrantOrSubsidy320MinViewport = kDialogs320MinViewport;

/// Wide regression sentinel.
const Size kGrantOrSubsidy320WideViewport = kDialogs320WideRegressionViewport;

/// Two-player fixture: `gp1` human (seeded treasury), `gp2` rival target.
Game buildGrantOrSubsidy320Game({required int humanTreasury}) {
  return Game(
    id: 'g_dipl20001',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'Castile',
        isHuman: true,
        treasury: humanTreasury,
      ),
      const Player(
        id: 'gp2',
        displayName: 'England',
        isHuman: false,
        treasury: 0,
      ),
    ],
  );
}
