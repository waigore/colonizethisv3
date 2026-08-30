// Shared 320 dp dialog pump harness (Refs #4013 / #4058 / #4117 slice F).
// SPEC: SPEC/ui/mobile-adaptation.md § 7; SPEC/program/repo-lint.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show CivilianMissingWorkOrderEntry;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';

const dialogs320Gp1 = 'gp1';

const dialogs320AttackerWinsFlips = QuickBattleResult(
  winner: QuickBattleWinner.attacker,
  attackerCasualties: ['a3'],
  defenderCasualties: ['d1', 'd2'],
  provinceFlips: true,
);

const dialogs320OneLevyArmy = Army(
  id: 'army_1',
  ownerId: dialogs320Gp1,
  regionId: 'oldWorld',
  stationedProvinceId: 'oldWorld|cap',
  regimentUnitIds: ['levy_1'],
);

final dialogs320OneCarrackAtSea = Fleet(
  id: 'f_split',
  ownerId: dialogs320Gp1,
  regionId: 'oldWorld',
  seaZoneId: 's1',
  shipTypeIds: const ['carrack'],
);

final dialogs320SourceFleetAtSea = Fleet(
  id: 'f_src',
  ownerId: dialogs320Gp1,
  regionId: 'oldWorld',
  seaZoneId: 's1',
  shipTypeIds: const ['carrack'],
);

final dialogs320HomeFleetInPort = Fleet(
  id: 'home_fleet',
  ownerId: dialogs320Gp1,
  regionId: 'oldWorld',
  inPortAtProvinceId: 'oldWorld|cap',
  shipTypeIds: const ['carrack'],
);

Game dialogs320OrdersGame({
  List<Province> oldWorldProvinces = const [],
  List<Unit> oldWorldUnits = const [],
  Map<String, String> seaZoneDisplayNameById = const {},
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: oldWorldUnits),
      newWorld: const RegionData(),
      seaZoneDisplayNameById: seaZoneDisplayNameById,
    ),
    players: const [
      Player(id: dialogs320Gp1, displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

Game dialogs320GameWithOneRegimentArmy() => dialogs320OrdersGame(
      oldWorldProvinces: const [
        Province(id: 'cap', regionId: 'oldWorld', displayName: 'Lisbon'),
      ],
      oldWorldUnits: [
        Unit(
          id: 'levy_1',
          type: 'peasant_levy',
          ownerId: dialogs320Gp1,
          locationProvinceId: 'oldWorld|cap',
        ),
      ],
    );

Game dialogs320MinimalSeaZoneGame() => dialogs320OrdersGame(
      seaZoneDisplayNameById: const {'oldWorld|s1': 'Adriatic Display'},
    );

Game dialogs320GameWithCapitalAndSeaZone() => dialogs320OrdersGame(
      oldWorldProvinces: const [
        Province(id: 'cap', regionId: 'oldWorld', displayName: 'Lisbon'),
      ],
      seaZoneDisplayNameById: const {'oldWorld|s1': 'Adriatic'},
    );

/// Pumps [dialog] at [size] and asserts no overflow plus [expectFinders].
Future<void> pinDialogs320At(
  WidgetTester tester,
  Widget dialog, {
  required Size size,
  String? overflowReason,
  required List<Finder> expectFinders,
}) async {
  await pumpDialogs320At(tester, dialog, size: size);
  expect(tester.takeException(), isNull, reason: overflowReason);
  for (final finder in expectFinders) {
    expect(finder, findsOneWidget);
  }
}

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md § 7.
const Size kDialogs320MinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel for the same overflow contract.
const Size kDialogs320WideRegressionViewport = Size(1024, 768);

/// Pumps [dialog] at [size] under the running editorial-monocle theme.
///
/// Canonical Center-host for governed `*_320dp_min_viewport_test.dart` dialog /
/// overlay pins — do not re-declare `Scaffold(body: Center(child: …))`.
Future<void> pumpDialogs320At(
  WidgetTester tester,
  Widget dialog, {
  required Size size,
  bool settle = true,
  Locale? locale,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    child: Scaffold(body: Center(child: dialog)),
    settle: settle,
  );
}

/// Three-GP fixture for call-to-arms / overture overlay name resolution.
Game buildThreeGpDialogueOverlayGame({
  String id = 'dialogue_320',
  String humanId = 'gp_player',
  String humanName = 'Player',
  String allyId = 'gp_portugal',
  String allyName = 'Portugal',
  String otherId = 'gp_spain',
  String otherName = 'Spain',
  int turnNumber = 5,
}) => Game(
  id: id,
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: [
    Player(id: humanId, displayName: humanName, isHuman: true),
    Player(id: allyId, displayName: allyName, isHuman: false),
    Player(id: otherId, displayName: otherName, isHuman: false),
  ],
);
