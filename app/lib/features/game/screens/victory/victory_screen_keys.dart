import 'package:flutter/material.dart';

/// Stable widget keys for the Victory screen (`GAME70001`).
abstract final class VictoryScreenKeys {
  static const Key topBarKey = ValueKey<String>('victoryScreenTopBar');
  static const Key conditionsSectionKey =
      ValueKey<String>('victoryScreenConditions');
  static const Key standingsSectionKey =
      ValueKey<String>('victoryScreenStandings');
  static const Key endStateBannerKey = ValueKey<String>('victoryScreenEndState');

  static Key standingRowKey(String playerId) =>
      ValueKey<String>('victoryStandingRow_$playerId');

  static Key standingExpandKey(String playerId) =>
      ValueKey<String>('victoryStandingExpand_$playerId');

  static Key powerBreakdownKey(String playerId) =>
      ValueKey<String>('victoryPowerBreakdown_$playerId');

  static const Key politicalMinimapSectionKey =
      ValueKey<String>('victoryPoliticalMinimapSection');
  static const Key politicalMinimapGestureKey =
      ValueKey<String>('victoryPoliticalMinimapGesture');
  static const Key politicalMinimapPaintKey =
      ValueKey<String>('victoryPoliticalMinimapPaint');
  static const Key politicalMinimapInspectKey =
      ValueKey<String>('victoryPoliticalMinimapInspect');
}
