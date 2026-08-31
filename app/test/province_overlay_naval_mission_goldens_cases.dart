// Golden scenario table for MAP20001 naval mission overlay pins (Refs #4413, #4305).

import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart';
import 'package:flutter/material.dart';

class NavalMissionGoldenCase {
  const NavalMissionGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showBlockade,
    required this.blockadeEnabled,
    required this.showBeachhead,
    required this.beachheadEnabled,
    this.blockadeTooltip = '',
    this.beachheadTooltip = '',
    this.blockadeStatus = ProvinceBlockadeStatus.none,
    this.overlaySize = const Size(460, 680),
    this.surfaceSize = const Size(640, 720),
  });

  final String name;
  final String goldenFile;
  final bool showBlockade;
  final bool blockadeEnabled;
  final bool showBeachhead;
  final bool beachheadEnabled;
  final String blockadeTooltip;
  final String beachheadTooltip;
  final ProvinceBlockadeStatus blockadeStatus;
  final Size overlaySize;
  final Size surfaceSize;
}

const String kNavalMissionGoldenNotAtSea =
    'A fleet must be at sea beside this coast. Fleets in port cannot take missions.';

const List<NavalMissionGoldenCase> navalMissionGoldenCases = [
  NavalMissionGoldenCase(
    name: 'Naval Blockade enabled',
    goldenFile: 'goldens/province_overlay_blockade_enabled.png',
    showBlockade: true,
    blockadeEnabled: true,
    showBeachhead: false,
    beachheadEnabled: false,
  ),
  NavalMissionGoldenCase(
    name: 'Naval Blockade disabled',
    goldenFile: 'goldens/province_overlay_blockade_disabled.png',
    showBlockade: true,
    blockadeEnabled: false,
    showBeachhead: false,
    beachheadEnabled: false,
    blockadeTooltip: kNavalMissionGoldenNotAtSea,
  ),
  NavalMissionGoldenCase(
    name: 'Naval Blockade hidden',
    goldenFile: 'goldens/province_overlay_blockade_hidden.png',
    showBlockade: false,
    blockadeEnabled: false,
    showBeachhead: false,
    beachheadEnabled: false,
  ),
  NavalMissionGoldenCase(
    name: 'Naval Beachhead enabled',
    goldenFile: 'goldens/province_overlay_beachhead_enabled.png',
    showBlockade: false,
    blockadeEnabled: false,
    showBeachhead: true,
    beachheadEnabled: true,
  ),
  NavalMissionGoldenCase(
    name: 'Naval Beachhead disabled',
    goldenFile: 'goldens/province_overlay_beachhead_disabled.png',
    showBlockade: false,
    blockadeEnabled: false,
    showBeachhead: true,
    beachheadEnabled: false,
    beachheadTooltip: kNavalMissionGoldenNotAtSea,
  ),
  NavalMissionGoldenCase(
    name: 'Naval Beachhead hidden',
    goldenFile: 'goldens/province_overlay_beachhead_hidden.png',
    showBlockade: false,
    blockadeEnabled: false,
    showBeachhead: false,
    beachheadEnabled: false,
  ),
  NavalMissionGoldenCase(
    name: 'Naval Blockade/Beachhead 320 dp',
    goldenFile: 'goldens/province_overlay_blockade_beachhead_320.png',
    showBlockade: true,
    blockadeEnabled: true,
    showBeachhead: true,
    beachheadEnabled: true,
    overlaySize: Size(320, 680),
    surfaceSize: Size(640, 720),
  ),
  NavalMissionGoldenCase(
    name: 'Naval Under blockade',
    goldenFile: 'goldens/province_overlay_under_blockade.png',
    showBlockade: false,
    blockadeEnabled: false,
    showBeachhead: false,
    beachheadEnabled: false,
    blockadeStatus: ProvinceBlockadeStatus.portBlockaded,
  ),
  NavalMissionGoldenCase(
    name: 'Naval Under blockade capital',
    goldenFile: 'goldens/province_overlay_under_blockade_capital.png',
    showBlockade: false,
    blockadeEnabled: false,
    showBeachhead: false,
    beachheadEnabled: false,
    blockadeStatus: ProvinceBlockadeStatus.capitalBlockaded,
  ),
];
