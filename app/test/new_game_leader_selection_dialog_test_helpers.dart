// Chrome text constants for NewGameLeaderSelectionDialog widget tests (Refs #4734).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

const List<String> kNewGameLeaderDialogChromeTexts = <String>[
  'Choose nations and leaders',
  'Choose six great powers and a leader variant for each',
  'Slot 1',
  'YOU',
  'Slot 2',
  'Slot 6',
  'Game seed',
  'Enter 0 for a random seed',
  'Infinite mode',
  'Terrain variation:',
  '50%',
  '0% flat — 100% extreme',
];

const String kNewGameLeaderInfiniteModeHelperText =
    'Skips the year-1800 calendar stop. Owning 31 or more Old World '
    'provinces still ends the campaign. You cannot change this after '
    'Start.';

const Size kNewGameLeaderDuplicateSurface = Size(900, 1600);
const List<String> kNewGameLeaderDuplicateEnglandIds = <String>[
  'england',
  'france',
  'spain',
  'portugal',
  'netherlands',
  'england',
];

GameSetupConfig get newGameLeaderDuplicateEnglandConfig =>
    GameSetupConfig(selectedGreatPowerIds: kNewGameLeaderDuplicateEnglandIds);
