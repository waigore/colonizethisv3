/// Sole-GP / unwinnable-frontier / critical-hold own-vs-partner peace builder.
library;

import 'expand_phase_peace_test_support_core.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Sole-GP / unwinnable-frontier / critical-hold Game builder used by the
/// expand peace matrix sole-GP case modules and the sole-GP / critical
/// OW-hold peace pins (Refs #3997 fixture consolidation).
///
/// Distinct from [buildPeerExpandPeaceGame]: preserves turn 80, relation
/// score `30` on minor arms, optional [extraInvadableMinorOwnerId]
/// province, and optional partner-owned [invadablePartnerProvince] at
/// `oldWorld|invadable_partner` (GP-only frontier carve-out pins).
Game buildOwnVsPartnerExpandPeaceGame({
  required int ownProvinces,
  required int partnerProvinces,
  String partnerId = kExpandPeaceGpPartner,
  String ownPlayerId = kExpandPeaceGpOwn,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? minorId,
  int minorProvinces = 0,
  String? extraInvadableMinorOwnerId,
  bool invadablePartnerProvince = false,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
  bool atWarWithMinor = false,
  String? gameId,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${ownPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownPlayerId,
      ),
    for (var i = 1; i <= partnerProvinces; i++)
      Province(
        id: 'oldWorld|${partnerId}_$i',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
    if (extraGpId != null)
      for (var i = 1; i <= extraGpProvinces; i++)
        Province(
          id: 'oldWorld|${extraGpId}_$i',
          regionId: 'oldWorld',
          ownerId: extraGpId,
        ),
    if (minorId != null)
      for (var i = 1; i <= minorProvinces; i++)
        Province(
          id: 'oldWorld|${minorId}_$i',
          regionId: 'oldWorld',
          ownerId: minorId,
        ),
    if (extraInvadableMinorOwnerId != null)
      Province(
        id: 'oldWorld|invadable_minor',
        regionId: 'oldWorld',
        ownerId: extraInvadableMinorOwnerId,
      ),
    if (invadablePartnerProvince)
      Province(
        id: 'oldWorld|invadable_partner',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
  ];

  final players = <Player>[
    Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
    Player(id: partnerId, displayName: partnerId, isHuman: false),
    if (extraGpId != null)
      Player(id: extraGpId, displayName: extraGpId, isHuman: false),
  ];

  final minorNations = <MinorNation>[
    if (minorId != null) MinorNation(id: minorId, displayName: minorId),
    if (extraInvadableMinorOwnerId != null)
      MinorNation(
        id: extraInvadableMinorOwnerId,
        displayName: extraInvadableMinorOwnerId,
      ),
  ];

  final relations = <DiplomacyRelation>[
    if (atWarWithPartner)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: partnerId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (extraGpId != null && atWarWithExtraGp)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: extraGpId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (minorId != null && atWarWithMinor)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: minorId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id: gameId ?? 'g-unwinnable-sole-gp-${ownProvinces}_vs_$partnerProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    diplomacyRelations: relations,
  );
}

