import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Highlighted train recommendations keyed by unit type id (Refs #4307 Slice C).
Map<String, MilitaryCounselRecommendation>
militaryCounselTrainHighlightsByUnitType({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
}) {
  final highlights = <String, MilitaryCounselRecommendation>{};
  for (final recommendation in rankMilitaryCounselRecommendations(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    topology: topology,
  )) {
    if (!recommendation.isHighlight) continue;
    if (recommendation.kind != MilitaryCounselRecommendationKind.trainUnit) {
      continue;
    }
    final unitType = recommendation.unitType;
    if (unitType == null) continue;
    highlights.putIfAbsent(unitType, () => recommendation);
  }
  return highlights;
}
