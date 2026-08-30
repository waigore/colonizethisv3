/// Development counsel recommendation DTOs and reason keys.
library;

enum DevelopmentCounselReasonKey {
  coastalPort,
  resourceCoast,
  newWorldCoast,
  overseasLinkage,
}

enum DevelopmentCounselRecommendationKind {
  buildPort,
}

/// One ranked development counsel recommendation (≤3 per turn).
final class DevelopmentCounselRecommendation {
  const DevelopmentCounselRecommendation({
    required this.recommendationId,
    required this.kind,
    required this.rankScore,
    required this.briefReasonKey,
    required this.detailReasonKeys,
    required this.isHighlight,
    required this.targetTileKey,
    required this.provinceId,
    this.provinceDisplayName,
    this.unitId,
  });

  final String recommendationId;
  final DevelopmentCounselRecommendationKind kind;
  final double rankScore;
  final DevelopmentCounselReasonKey briefReasonKey;
  final List<DevelopmentCounselReasonKey> detailReasonKeys;
  final bool isHighlight;
  final String targetTileKey;
  final String provinceId;
  final String? provinceDisplayName;
  final String? unitId;
}
