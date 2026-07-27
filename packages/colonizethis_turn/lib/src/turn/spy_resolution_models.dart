import 'package:colonizethis_models/colonizethis_models.dart';

/// Spy killed during spy-resolution (Refs #3834 R9).
class SpyCaughtDetail {
  const SpyCaughtDetail({
    required this.unitId,
    required this.spyOwnerId,
    required this.territoryOwnerId,
    required this.provinceId,
  });

  final String unitId;
  final String spyOwnerId;
  final String territoryOwnerId;
  final String provinceId;
}

/// Spy defected during spy-resolution (Refs #3834 R9).
class SpyDefectedDetail {
  const SpyDefectedDetail({
    required this.unitId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.provinceId,
  });

  final String unitId;
  final String previousOwnerId;
  final String newOwnerId;
  final String provinceId;
}

/// Result of the pre-Research spy-resolution sub-step (Refs #3834 R12).
class SpyResolutionResult {
  const SpyResolutionResult({
    required this.game,
    this.killedSpyUnitIds = const [],
    this.defectedSpyUnitIds = const [],
    this.caughtSpies = const [],
    this.defectedSpies = const [],
    this.diplomacyPenaltiesApplied = 0,
  });

  final Game game;
  final List<String> killedSpyUnitIds;
  final List<String> defectedSpyUnitIds;
  final List<SpyCaughtDetail> caughtSpies;
  final List<SpyDefectedDetail> defectedSpies;
  final int diplomacyPenaltiesApplied;
}
