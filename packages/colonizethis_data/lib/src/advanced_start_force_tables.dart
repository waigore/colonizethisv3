import 'package:colonizethis_models/colonizethis_models.dart';

/// Per-tier economy bootstrap values applied to every Great Power.
class AdvancedStartTierParams {
  const AdvancedStartTierParams({
    required this.treasury,
    required this.peasants,
    this.apprentices = 0,
  });

  final int treasury;
  final int peasants;
  final int apprentices;
}

AdvancedStartTierParams advancedStartTierParams(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => const AdvancedStartTierParams(
      treasury: 0,
      peasants: 0,
    ),
    AdvancedStartType.turns50 => const AdvancedStartTierParams(
      treasury: 20000,
      peasants: 16,
    ),
    AdvancedStartType.turns100 => const AdvancedStartTierParams(
      treasury: 40000,
      peasants: 16,
      apprentices: 4,
    ),
  };
}

/// Civilian unit counts per tier. SPEC/game/advanced-starts.md.
const Map<String, int> kAdvancedStart50TurnCivilianCounts = {
  kUnitTypeExplorer: 3,
  kUnitTypeBuilder: 3,
  kUnitTypeEngineer: 2,
  kUnitTypeSpy: 1,
  kUnitTypeMerchant: 1,
};

const Map<String, int> kAdvancedStart100TurnCivilianCounts = {
  kUnitTypeExplorer: 4,
  kUnitTypeBuilder: 4,
  kUnitTypeEngineer: 3,
  kUnitTypeSpy: 2,
  kUnitTypeMerchant: 2,
  kUnitTypeRailBuilder: 1,
};

Map<String, int> advancedStartCivilianCounts(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => const {},
    AdvancedStartType.turns50 => kAdvancedStart50TurnCivilianCounts,
    AdvancedStartType.turns100 => kAdvancedStart100TurnCivilianCounts,
  };
}

int advancedStartRegimentCount(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => 6,
    AdvancedStartType.turns100 => 12,
  };
}

/// Fixed minimum cargo ships per tier. 100-turn dynamic formula applies after NW dev.
int advancedStartCargoShipCount(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => 1,
    AdvancedStartType.turns100 => 6,
  };
}

/// Advanced-start cargo ship type id (Galleon per SPEC/game/advanced-starts.md).
const String kAdvancedStartCargoShipTypeId = 'galleon';

OvertureStage advancedStartDiplomacyOvertureStage(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => OvertureStage.none,
    AdvancedStartType.turns50 => OvertureStage.tradeConsulate,
    AdvancedStartType.turns100 => OvertureStage.embassy,
  };
}
