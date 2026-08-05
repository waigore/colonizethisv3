import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_pass_context.dart';

/// Shared pass-level context for development panel candidate resolution
/// (Refs #4258 Slice A).
///
/// Amortizes [IncrementalCandidateValidator] and [OrderResolutionContext]
/// across builder/engineer loops in assign and road-first paths, matching
/// `SuggestionPassContext` used by `suggestWorkOrders`.
class DevelopmentPanelPassContext {
  DevelopmentPanelPassContext._({
    required this.view,
    required this.candidateValidator,
    required this.resolution,
  });

  final PlayerView view;
  final IncrementalCandidateValidator candidateValidator;
  final OrderResolutionContext resolution;

  /// Standard pass setup for development panel tile-key probes.
  factory DevelopmentPanelPassContext.fromPlayerView({
    required Game game,
    required MapTopology topology,
    required String playerId,
    required Orders currentOrders,
    required Map<String, TileMapResult> tileMapByRegion,
  }) {
    final view = buildPlayerView(game, topology, playerId);
    final pass = SuggestionPassContext.forPlayerView(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      familyLabel: 'developmentPanel',
      tileMapByRegion: tileMapByRegion,
    );
    return DevelopmentPanelPassContext._(
      view: pass.view,
      candidateValidator: pass.candidateValidator,
      resolution: pass.resolution,
    );
  }
}
