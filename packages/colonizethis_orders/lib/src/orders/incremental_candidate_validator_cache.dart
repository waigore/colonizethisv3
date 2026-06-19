/// Per-pass memoization state for [IncrementalCandidateValidator].
///
/// Extracted into a dedicated holder so the validator's probe helpers can live
/// in a standalone companion library (`incremental_candidate_validator_replay.dart`)
/// with explicit imports instead of `part of` fragments that inherit the host
/// library's private scope (Refs #3543 — de-part-file orders; extraction-shape
/// policy in `SPEC/program/dart-file-non-comment-line-size.md` § Extraction
/// shape). The fields are mutable, package-internal cache slots populated lazily
/// during a single suggestion pass (Refs #2394, #2692 S7); a fresh holder is
/// created per validator instance so behaviour matches the previous
/// instance-field caches exactly.
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_resolution_context.dart';
import 'order_validators.dart';

/// Holds the lazily-computed per-pass caches shared between
/// [IncrementalCandidateValidator] and its replay/projection probe helpers.
class IncrementalCandidateValidatorCache {
  Set<String>? devExclusiveTiles;
  Set<String>? civilianDraftMoveUnitIds;
  ({Stockpile stockpile, int treasury})? economyAfterBuildOrders;
  ({Stockpile stockpile, int treasury})? economyAfterBuildAndWorkOrders;

  /// When `false`, existing work orders in the base prefix failed incremental
  /// replay; every work probe must reject (Refs #2394).
  bool? workPrefixReplaySucceeded;
  ({
    Stockpile stockpile,
    int treasury,
    Set<String> seenUnitIds,
    Set<String> devExclusive,
  })?
  postWorkPrefixState;

  /// When `false`, existing build orders in the base prefix failed incremental
  /// replay; every build probe must reject (Refs #2394).
  bool? buildPrefixReplaySucceeded;
  ({Stockpile stockpile, int treasury, WorkerPool workers})?
  postBuildPrefixEconomy;

  /// When `false`, existing recruit worker orders in the base prefix failed
  /// incremental replay; every recruit-worker probe must reject (Refs #2692 S7).
  bool? recruitWorkerPrefixReplaySucceeded;
  ({Stockpile stockpile, int treasury, WorkerPool workers})?
  postRecruitWorkerPrefixEconomy;

  /// When `false`, existing diplomatic orders in the base prefix failed
  /// incremental replay; every diplomatic probe must reject (Refs #2394).
  bool? diplomaticPrefixReplaySucceeded;
  DiplomaticPrefixCheckpoint? postDiplomaticPrefixState;

  Map<String, Army>? armiesById;
  DiplomacyFactionMembership? factionMembership;
  NavalOrderValidator? navalOrderValidator;
  OrderResolutionContext? orderResolutionContext;
}
