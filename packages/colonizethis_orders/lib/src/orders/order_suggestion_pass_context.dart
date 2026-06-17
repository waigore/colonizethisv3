import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';

/// Shared pass-level context for order-suggestion families (Refs #3500 Phase 2).
///
/// Amortizes [IncrementalCandidateValidator] construction, faction membership,
/// and [OrderResolutionContext] resolution across candidate probes in one
/// `suggest*` call. SPEC/program/order-suggestions.md § Throughput bounds.
class SuggestionPassContext {
  SuggestionPassContext._({
    required this.view,
    required this.game,
    required this.topology,
    required this.currentOrders,
    required this.playerId,
    required this.candidateValidator,
    required this.factionMembership,
    required this.resolution,
    required this.familyLabel,
  });

  final PlayerView view;
  final Game game;
  final MapTopology topology;
  final Orders currentOrders;
  final String playerId;
  final IncrementalCandidateValidator candidateValidator;
  final DiplomacyFactionMembership factionMembership;
  final OrderResolutionContext resolution;
  final String familyLabel;

  /// Asserts [sharedCandidateValidator.playerId] matches [playerId] when set.
  static void assertSharedValidatorPlayerId(
    IncrementalCandidateValidator? sharedCandidateValidator,
    String playerId,
  ) {
    assert(
      sharedCandidateValidator == null ||
          sharedCandidateValidator.playerId == playerId,
      'sharedCandidateValidator playerId must match view.playerId',
    );
  }

  /// Standard pass setup for `suggest*` families sharing the same throughput
  /// hook contract (Refs #2394).
  factory SuggestionPassContext.forPlayerView({
    required PlayerView view,
    required Game game,
    required MapTopology topology,
    required Orders currentOrders,
    required String familyLabel,
    Map<String, TileMapResult>? tileMapByRegion,
    IncrementalCandidateValidator? sharedCandidateValidator,
    OrderResolutionContext? resolution,
    DiplomacyFactionMembership? factionMembership,

    /// When false, constructs via [IncrementalCandidateValidator.forPlayer]
    /// (move/army-move families). When true, uses
    /// [buildIncrementalCandidateValidator] (default for most families).
    bool useBuildIncrementalWrapper = true,

    /// When false, omits [factionMembership] from validator construction
    /// (naval families).
    bool includeFactionMembershipInBuild = true,
  }) {
    final playerId = view.playerId;
    assertSharedValidatorPlayerId(sharedCandidateValidator, playerId);
    orderSuggestionLog.d('$familyLabel player=$playerId');

    final effectiveFactionMembership =
        factionMembership ??
        sharedCandidateValidator?.factionMembershipSnapshot ??
        DiplomacyFactionMembership.from(game);

    final effectiveResolution =
        resolution ??
        effectiveOrderResolutionContext(
          view: view,
          game: game,
          sharedCandidateValidator: sharedCandidateValidator,
        );

    final candidateValidator =
        sharedCandidateValidator ??
        (useBuildIncrementalWrapper
            ? buildIncrementalCandidateValidator(
                game: game,
                topology: topology,
                playerId: playerId,
                baseOrders: currentOrders,
                tileMapByRegion: tileMapByRegion,
                resolution: effectiveResolution,
                factionMembership: includeFactionMembershipInBuild
                    ? effectiveFactionMembership
                    : null,
              )
            : IncrementalCandidateValidator.forPlayer(
                game: game,
                topology: topology,
                playerId: playerId,
                basePrefix: currentOrders,
                tileMapByRegion: tileMapByRegion,
                factionMembership: includeFactionMembershipInBuild
                    ? effectiveFactionMembership
                    : null,
                resolution: effectiveResolution,
              ));

    return SuggestionPassContext._(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      playerId: playerId,
      candidateValidator: candidateValidator,
      factionMembership: effectiveFactionMembership,
      resolution: effectiveResolution,
      familyLabel: familyLabel,
    );
  }

  void logExit({required int candidateCount, bool warnIfEmpty = false}) {
    orderSuggestionLog.d(
      '$familyLabel player=$playerId candidates=$candidateCount',
    );
    if (warnIfEmpty && candidateCount == 0) {
      orderSuggestionLog.w('$familyLabel no candidates player=$playerId');
    }
  }
}

/// Resolves [OrderResolutionContext] for a suggestion pass, reusing a shared
/// validator's embedded view when available (Refs #2394).
OrderResolutionContext effectiveOrderResolutionContext({
  required PlayerView view,
  required Game game,
  OrderResolutionContext? resolution,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  if (resolution != null) return resolution;
  if (sharedCandidateValidator != null) {
    return (
      view: sharedCandidateValidator.view,
      unitsById: sharedCandidateValidator.unitsById,
      provinceById: sharedCandidateValidator.view.provincesById,
    );
  }
  return orderResolutionContextFromView(view, game);
}

/// Full province ids owned by [playerId] from [view.provincesById].
Set<String> ownedProvinceIdsFromView(PlayerView view, String playerId) {
  return {
    for (final e in view.provincesById.entries)
      if (e.value.ownerId == playerId) e.key,
  };
}

/// Indexes existing orders by entity id → target id set for dedup during
/// suggestion probes.
Map<String, Set<String>> indexExistingTargetsByEntityId<T>(
  List<T>? orders,
  String Function(T order) entityId,
  String Function(T order) target, {
  bool skipEmptyTargets = false,
}) {
  final out = <String, Set<String>>{};
  for (final o in orders ?? const []) {
    final targetId = target(o);
    if (skipEmptyTargets && targetId.isEmpty) continue;
    out.putIfAbsent(entityId(o), () => <String>{}).add(targetId);
  }
  return out;
}

/// Deterministic capped probe loop shared by move and army-move suggestion
/// (Refs #3500 Phase 2). Skipped candidates do not count toward [maxProbes].
int runCappedSuggestionProbeLoop<T>({
  required Iterable<T> candidates,
  required bool Function(T candidate) shouldSkip,
  required bool Function(T candidate) probe,
  required void Function(T candidate) onAccepted,
  required int maxAccepted,
  required int maxProbes,
}) {
  var accepted = 0;
  var probeAttempts = 0;
  for (final candidate in candidates) {
    if (shouldSkip(candidate)) continue;
    probeAttempts++;
    if (probe(candidate)) {
      onAccepted(candidate);
      accepted++;
      if (accepted >= maxAccepted) break;
    }
    if (probeAttempts >= maxProbes) break;
  }
  return accepted;
}
