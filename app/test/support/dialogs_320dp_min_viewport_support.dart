// Shared 320 dp dialog pump harness (Refs #4013 / #4058).
// SPEC: SPEC/ui/mobile-adaptation.md § 7; SPEC/program/repo-lint.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';

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
