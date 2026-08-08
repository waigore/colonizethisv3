import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';

import 'planning_helpers.dart' show scaleWeightedBonus;

/// Returns the NW-tribe declare-war dominance bonus scaled by the soft-phase
/// NW acquisition weight (Refs #2847 Phase 3 diplomacy declare-war NW-tribe
/// bonus wiring).
int declareWarColonialNwTribeDominanceBonus({
  required double nwAcquisitionWeight,
}) => _scaleDeclareWarColonialNwTribeBonus(
  baseBonus: kDeclareWarColonialNwTribeDominanceBonus,
  nwAcquisitionWeight: nwAcquisitionWeight,
);

/// Returns the NW-tribe "priority over OW minor" declare-war bonus scaled by
/// the soft-phase NW acquisition weight (Refs #2847 Phase 3 diplomacy
/// declare-war NW-tribe bonus wiring).
int declareWarColonialNwTribePriorityOverOwMinorBonus({
  required double nwAcquisitionWeight,
}) => _scaleDeclareWarColonialNwTribeBonus(
  baseBonus: kDeclareWarColonialNwTribePriorityOverOwMinorBonus,
  nwAcquisitionWeight: nwAcquisitionWeight,
);

int _scaleDeclareWarColonialNwTribeBonus({
  required int baseBonus,
  required double nwAcquisitionWeight,
}) => scaleWeightedBonus(nwAcquisitionWeight, baseBonus);

/// Returns an OW declare-war additive bonus scaled by the soft-phase
/// OW conquest weight (Refs #2847 Phase 3 diplomacy declare-war OW
/// scoring).
int declareWarOldWorldConquestScaledBonus({
  required int baseBonus,
  required double oldWorldConquestWeight,
}) => scaleWeightedBonus(oldWorldConquestWeight, baseBonus);

/// Raises [currentScore] to the OW-conquest-scaled [floorBonus] floor, never
/// lowering it (Refs #3717 declare-war OW-conquest scoring-skeleton dedup).
int raiseToDeclareWarOldWorldConquestFloor({
  required int currentScore,
  required int floorBonus,
  required double oldWorldConquestWeight,
}) => math.max(
  currentScore,
  declareWarOldWorldConquestScaledBonus(
    baseBonus: floorBonus,
    oldWorldConquestWeight: oldWorldConquestWeight,
  ),
);
