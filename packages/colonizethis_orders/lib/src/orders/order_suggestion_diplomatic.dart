part of 'order_suggestion_naval_diplomatic.dart';

/// Per-target suggestion order: first candidate that passes the order engine wins.
/// SPEC/program/order-suggestions.md § Diplomatic orders.
List<DiplomaticOrder> _diplomaticCandidatesForTargetOrdered({
  required Game game,
  required String playerId,
  required Player player,
  required String targetId,
  required Set<String> knownTargetIds,
  required Set<String> knownFactionIds,
  required DiplomacyFactionMembership factionMembership,
  required Map<String, OvertureState> playerOverturesByTargetId,
}) {
  final treasury = player.treasury;
  final out = <DiplomaticOrder>[];
  if (targetId == playerId) return out;

  final rel = getRelation(game, playerId, targetId);
  final atWar = rel?.atWar ?? false;
  final atPeace = rel == null || rel.atPeace;
  final isGpTarget = game.playerById(targetId) != null;
  final targetIsMinorOrTribe = isMinorOrTribe(
    game,
    targetId,
    factionMembership: factionMembership,
  );

  if (knownTargetIds.contains(targetId) && atWar) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: targetId,
      ),
    );
  }
  if (isGpTarget &&
      rel != null &&
      rel.atPeace &&
      rel.level != RelationLevel.allied) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: targetId,
      ),
    );
  }
  if (targetIsMinorOrTribe && knownFactionIds.contains(targetId)) {
    final overtureOrder = _establishOvertureSuggestionOrder(
      game: game,
      playerId: playerId,
      targetId: targetId,
      treasury: treasury,
    );
    if (overtureOrder != null) out.add(overtureOrder);
  }

  final overtureRow = playerOverturesByTargetId[targetId];
  if (overtureRow != null) {
    if (overtureRow.hasEmbassy && treasury >= grantAidDefaultAmount) {
      out.add(
        DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: targetId,
          amount: grantAidDefaultAmount,
        ),
      );
    }
    if (overtureRow.hasConsulate && treasury >= setSubsidyDefaultAmount) {
      out.add(
        DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: targetId,
          amount: setSubsidyDefaultAmount,
        ),
      );
    }
  }

  if (knownTargetIds.contains(targetId) && atPeace) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: targetId,
      ),
    );
  }

  return out;
}

DiplomaticOrder? _establishOvertureSuggestionOrder({
  required Game game,
  required String playerId,
  required String targetId,
  required int treasury,
}) {
  final rel = getRelation(game, playerId, targetId);
  final atWar = rel?.atWar ?? false;
  if (atWar) return null;

  final existing = getOverture(game, playerId, targetId);
  final current = existing?.stage ?? OvertureStage.none;
  final next = current.next;
  if (next == null) return null;
  if (next == OvertureStage.tradeConsulate || next == OvertureStage.embassy) {
    final cost = next == OvertureStage.tradeConsulate
        ? overtureConsulateCost
        : overtureEmbassyCost;
    if (treasury < cost) return null;
  }
  if (next == OvertureStage.tradeConsulate ||
      next == OvertureStage.embassy ||
      next == OvertureStage.nap) {
    // O(1) player lookup (Refs #2394); minor/tribe overture stages require tech.
    final submitter = game.playerById(playerId);
    if (submitter?.techUnlocked?[kTechIdDiplomaticExpertise] != true) {
      return null;
    }
  }
  if (next == OvertureStage.joinEmpire) {
    final score = rel?.score ?? relationScoreNeutral;
    if (score < relationScoreMinFriendly) return null;
    final cost = joinEmpireCostForMinorOrTribe(game, targetId);
    if (treasury < cost) return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: targetId,
    overtureStage: next,
  );
}

/// Suggests candidate diplomatic orders that are valid and visible for [view.playerId].
/// SPEC/program/order-suggestions.md; SPEC/program/ai-systems-impl.md.
///
/// Throughput hook: when [sharedCandidateValidator] is supplied for the same
/// `(game, topology, playerId, currentOrders)` tuple, the pass-level validator
/// setup is skipped (Refs #2394).
List<DiplomaticOrder> suggestDiplomaticOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  orderSuggestionLog.d('suggestDiplomaticOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <DiplomaticOrder>[];
  final player = view.player;

  final knownFactionIds = knownDiplomaticTargetFactionIds(
    view: view,
    game: game,
    topology: topology,
  );

  // One membership snapshot for this pass: O(1) minor/tribe checks per target
  // and GP id sets without repeated list scans (Refs #2394).
  final factionMembership = DiplomacyFactionMembership.from(game);
  final otherGps = factionMembership.greatPowerIds.difference({playerId});
  final knownTargets = <String>{
    ...otherGps.where(knownFactionIds.contains),
    ...factionMembership.minorOrTribeIds.where(knownFactionIds.contains),
  };
  final knownTargetIds = knownTargets.toSet();

  // First matching overture row per target (same order as legacy linear scan).
  final playerOverturesByTargetId = <String, OvertureState>{};
  for (final o in game.overtureStates) {
    if (o.gpId != playerId) continue;
    playerOverturesByTargetId.putIfAbsent(o.targetId, () => o);
  }

  SuggestionPassContext.assertSharedValidatorPlayerId(
    sharedCandidateValidator,
    playerId,
  );
  final diplomaticResolution = effectiveOrderResolutionContext(
    view: view,
    game: game,
    sharedCandidateValidator: sharedCandidateValidator,
  );

  final unionTargets = <String>{
    ...knownTargets,
    ...otherGps,
    ...playerOverturesByTargetId.keys,
  };

  final sortedTargetIds = unionTargets.toList()..sort();
  var workingOrders = currentOrders;
  // Rebind [basePrefix] per target via [forBasePrefix]; pay view/units/membership
  // setup once for the whole suggestion pass (Refs #2394).
  var passValidator = sharedCandidateValidator != null
      ? (sharedCandidateValidator.basePrefix == workingOrders
            ? sharedCandidateValidator
            : sharedCandidateValidator.forBasePrefix(workingOrders))
      : buildIncrementalCandidateValidator(
          game: game,
          topology: topology,
          playerId: playerId,
          baseOrders: workingOrders,
          tileMapByRegion: tileMapByRegion,
          resolution: diplomaticResolution,
          factionMembership: factionMembership,
        );
  for (final targetId in sortedTargetIds) {
    if (targetId == playerId) continue;

    final candidates = _diplomaticCandidatesForTargetOrdered(
      game: game,
      playerId: playerId,
      player: player,
      targetId: targetId,
      knownTargetIds: knownTargetIds,
      knownFactionIds: knownFactionIds,
      factionMembership: factionMembership,
      playerOverturesByTargetId: playerOverturesByTargetId,
    );
    var trialOrders = workingOrders;

    // One incremental validator per trial prefix: amortizes validator setup
    // across all candidates in the pass (Refs #2394).
    final prefixPassValidator = passValidator.forBasePrefix(trialOrders);
    passValidator = prefixPassValidator;
    var prefixPassAcceptedOrder = false;
    for (final candidate in candidates) {
      if (candidate.type == DiplomaticOrderType.grantAid ||
          candidate.type == DiplomaticOrderType.setSubsidy) {
        continue;
      }
      if (!isDiplomaticOrderAcceptedWithValidator(
        prefixPassValidator,
        candidate,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
      prefixPassAcceptedOrder = true;
      break;
    }

    // Rebind only when the non-economic pass changed the trial prefix; when
    // it did not accept anything, economic probes share [prefixPassValidator].
    final economicPassValidator = prefixPassAcceptedOrder
        ? prefixPassValidator.forBasePrefix(trialOrders)
        : prefixPassValidator;
    if (prefixPassAcceptedOrder) {
      passValidator = economicPassValidator;
    }
    for (final candidate in candidates) {
      if (candidate.type != DiplomaticOrderType.grantAid &&
          candidate.type != DiplomaticOrderType.setSubsidy) {
        continue;
      }
      if (!isDiplomaticOrderAcceptedWithValidator(
        economicPassValidator,
        candidate,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
    }

    workingOrders = trialOrders;
    // Keep [passValidator] aligned with accumulated **workingOrders** before the
    // next target (including economic-only accepts that did not update
    // [passValidator] in the primary/economic split above). Refs #2394.
    passValidator = passValidator.forBasePrefix(workingOrders);
  }

  suggestions.sort((a, b) {
    final t = a.type.index.compareTo(b.type.index);
    if (t != 0) return t;
    final idCmp = a.targetFactionId.compareTo(b.targetFactionId);
    if (idCmp != 0) return idCmp;
    final stageCmp = (a.overtureStage?.index ?? -1).compareTo(
      b.overtureStage?.index ?? -1,
    );
    if (stageCmp != 0) return stageCmp;
    return (a.amount ?? 0).compareTo(b.amount ?? 0);
  });
  orderSuggestionLog.d(
    'suggestDiplomaticOrders player=$playerId candidates=${suggestions.length}',
  );
  return suggestions;
}

/// Declare-war candidates only. Used by Full AI `declareWarOnly` diplomacy pass
/// so `establishOverture` does not block war per target (Refs #2504).
/// SPEC/program/order-suggestions.md § Declare-war-only suggestions.
List<DiplomaticOrder> suggestDeclareWarOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  orderSuggestionLog.d('suggestDeclareWarOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <DiplomaticOrder>[];

  final knownFactionIds = knownDiplomaticTargetFactionIds(
    view: view,
    game: game,
    topology: topology,
  );

  final factionMembership = DiplomacyFactionMembership.from(game);
  final otherGps = factionMembership.greatPowerIds.difference({playerId});
  final knownTargets = <String>{
    ...otherGps.where(knownFactionIds.contains),
    ...factionMembership.minorOrTribeIds.where(knownFactionIds.contains),
  };
  final knownTargetIds = knownTargets.toSet();

  SuggestionPassContext.assertSharedValidatorPlayerId(
    sharedCandidateValidator,
    playerId,
  );
  final declareWarResolution = effectiveOrderResolutionContext(
    view: view,
    game: game,
    sharedCandidateValidator: sharedCandidateValidator,
  );

  final sortedTargetIds = knownTargetIds.toList()..sort();
  var passValidator = sharedCandidateValidator != null
      ? (sharedCandidateValidator.basePrefix == currentOrders
            ? sharedCandidateValidator
            : sharedCandidateValidator.forBasePrefix(currentOrders))
      : buildIncrementalCandidateValidator(
          game: game,
          topology: topology,
          playerId: playerId,
          baseOrders: currentOrders,
          tileMapByRegion: tileMapByRegion,
          resolution: declareWarResolution,
          factionMembership: factionMembership,
        );

  for (final targetId in sortedTargetIds) {
    if (targetId == playerId) continue;
    final rel = getRelation(game, playerId, targetId);
    final atPeace = rel == null || rel.atPeace;
    if (!atPeace) continue;

    final candidate = DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: targetId,
    );
    if (isDiplomaticOrderAcceptedWithValidator(passValidator, candidate)) {
      suggestions.add(candidate);
    }
  }

  suggestions.sort((a, b) => a.targetFactionId.compareTo(b.targetFactionId));
  orderSuggestionLog.d(
    'suggestDeclareWarOrders player=$playerId candidates=${suggestions.length}',
  );
  return suggestions;
}
