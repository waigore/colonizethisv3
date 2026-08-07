/// Land battle context value types. SPEC/program/combat-resolution.md.
library;

/// Battle context for one contested province. SPEC/program/combat-resolution.md.
class BattleContext {
  const BattleContext({
    required this.provinceId,
    required this.regionId,
    required this.defenderFactionId,
    required this.defenderUnitIds,
    this.defenderArmyIds = const [],
    this.primaryDefenderArmyId,
    this.defenderGeneralId,
    this.defenderGeneralMedals = 0,
    required this.attackers,
    required this.fortLevel,
    required this.terrain,
  });

  final String provinceId;
  final String regionId;
  final String defenderFactionId;
  final List<String> defenderUnitIds;
  final List<String> defenderArmyIds;
  final String? primaryDefenderArmyId;
  final String? defenderGeneralId;
  final int defenderGeneralMedals;
  final List<AttackingSide> attackers;
  final int fortLevel;
  final String terrain;

  bool get isSiege => fortLevel >= 1;

  BattleContext copyWith({
    String? provinceId,
    String? regionId,
    String? defenderFactionId,
    List<String>? defenderUnitIds,
    List<String>? defenderArmyIds,
    String? primaryDefenderArmyId,
    bool clearPrimaryDefenderArmyId = false,
    String? defenderGeneralId,
    bool clearDefenderGeneralId = false,
    int? defenderGeneralMedals,
    List<AttackingSide>? attackers,
    int? fortLevel,
    String? terrain,
  }) {
    return BattleContext(
      provinceId: provinceId ?? this.provinceId,
      regionId: regionId ?? this.regionId,
      defenderFactionId: defenderFactionId ?? this.defenderFactionId,
      defenderUnitIds: defenderUnitIds ?? this.defenderUnitIds,
      defenderArmyIds: defenderArmyIds ?? this.defenderArmyIds,
      primaryDefenderArmyId: clearPrimaryDefenderArmyId
          ? null
          : (primaryDefenderArmyId ?? this.primaryDefenderArmyId),
      defenderGeneralId: clearDefenderGeneralId
          ? null
          : (defenderGeneralId ?? this.defenderGeneralId),
      defenderGeneralMedals:
          defenderGeneralMedals ?? this.defenderGeneralMedals,
      attackers: attackers ?? this.attackers,
      fortLevel: fortLevel ?? this.fortLevel,
      terrain: terrain ?? this.terrain,
    );
  }
}

/// One attacking army in a battle. SPEC/program/combat-resolution.md.
class AttackingSide {
  const AttackingSide({
    required this.factionId,
    this.armyId = '',
    required this.unitIds,
    this.generalId,
    this.generalMedals = 0,
  });

  final String factionId;
  final String armyId;
  final List<String> unitIds;
  final String? generalId;
  final int generalMedals;

  AttackingSide copyWith({
    String? factionId,
    String? armyId,
    List<String>? unitIds,
    String? generalId,
    bool clearGeneralId = false,
    int? generalMedals,
  }) {
    return AttackingSide(
      factionId: factionId ?? this.factionId,
      armyId: armyId ?? this.armyId,
      unitIds: unitIds ?? this.unitIds,
      generalId: clearGeneralId ? null : (generalId ?? this.generalId),
      generalMedals: generalMedals ?? this.generalMedals,
    );
  }
}
