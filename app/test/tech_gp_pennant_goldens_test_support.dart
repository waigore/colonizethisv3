// Shared fixtures for GP tech-pennant goldens (Refs #3862 / #4642).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'golden_capture_harness.dart';

import 'package:colonizethis_app/config/themes.dart';

import 'panel_test_fixtures.dart';

const Map<String, List<int>> kPennantGoldenColorOverride = {
  'gp1': [200, 40, 40],
  'gp2': [40, 160, 40],
  'gp3': [40, 80, 200],
  'gp4': [220, 180, 60],
};

Game pennantGoldenGame({required List<Player> players}) {
  return buildPanelTestGame(
    players: players,
  ).copyWith(greatPowerColorOverride: kPennantGoldenColorOverride);
}

Game cropRotationResearchersGame({required String contextPlayerId}) {
  return pennantGoldenGame(
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP One',
        isHuman: contextPlayerId == 'gp1',
        techUnlocked: const {kTechIdCropRotation: true},
      ),
      Player(
        id: 'gp2',
        displayName: 'GP Two',
        isHuman: contextPlayerId == 'gp2',
      ),
      Player(
        id: 'gp3',
        displayName: 'GP Three',
        isHuman: false,
        techUnlocked: const {kTechIdCropRotation: true},
      ),
    ],
  );
}

Game sawMillChooseTechGame() {
  return pennantGoldenGame(
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP One',
        isHuman: true,
        techUnlocked: const {kTechIdSawMill: true},
      ),
      Player(
        id: 'gp2',
        displayName: 'GP Two',
        isHuman: false,
        techUnlocked: const {kTechIdSawMill: true},
      ),
    ],
  );
}

Game observeGp4Game() {
  return pennantGoldenGame(
    players: [
      const Player(id: 'gp1', displayName: 'GP One', isHuman: false),
      const Player(id: 'gp2', displayName: 'GP Two', isHuman: false),
      const Player(id: 'gp3', displayName: 'GP Three', isHuman: false),
      Player(
        id: 'gp4',
        displayName: 'GP Four',
        isHuman: true,
        techUnlocked: const {kTechIdCropRotation: true},
      ),
    ],
  );
}

Widget pennantGoldenHost({required Key boundaryKey, required Widget child}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: child,
  );
}
