import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';

/// Minimum minor nations required for a GA observer game. Refs #3447.
const int kGaMinMinorNationCount = 3;

/// Minimum tribes required for a GA observer game. Refs #3447.
const int kGaMinTribeCount = 3;

/// App-default per-Great-Power Old World province target (60 OW − 6 × 3 minor
/// reservations = 42 ÷ 6 GPs = 7). SPEC/program/ga-setup-profile.md. Refs #3447.
const int kGpOwTargetPerGp = 7;

/// Validates GA faction minimums, throwing [FormatException] on violation.
///
/// Shared by [GaConfig.fromJson] and [buildGaSetupProfile] so both the config
/// path and the profile builder enforce the same minimum. Refs #3447.
void validateGaFactionMinimums({
  required int minorNationCount,
  required int tribeCount,
}) {
  if (minorNationCount < kGaMinMinorNationCount) {
    throw FormatException(
      'minorNationCount ($minorNationCount) must be at least '
      '$kGaMinMinorNationCount for GA observer games',
    );
  }
  if (tribeCount < kGaMinTribeCount) {
    throw FormatException(
      'tribeCount ($tribeCount) must be at least '
      '$kGaMinTribeCount for GA observer games',
    );
  }
}

/// A GA setup profile: a derived [GameSetupConfig] plus per-faction province
/// targets. SPEC/program/ga-setup-profile.md. Refs #3447.
class GaSetupProfile {
  const GaSetupProfile({
    required this.setupConfig,
    required this.gpOwTargetPerGp,
    required this.minorOwTargets,
    required this.tribeNwTargets,
  });

  /// Derived, budget-scaled game setup configuration.
  final GameSetupConfig setupConfig;

  /// Per-Great-Power Old World province target (always [kGpOwTargetPerGp]).
  final int gpOwTargetPerGp;

  /// Equal per-minor Old World province targets (length == minor count).
  final List<int> minorOwTargets;

  /// Equal per-tribe New World province targets (length == tribe count).
  final List<int> tribeNwTargets;
}

/// Builds a realistic, budget-scaled GA setup profile for [selectedGreatPowerIds].
///
/// Derives `numProvincesOldWorld = gpCount × [kGpOwTargetPerGp] + minorCount ×
/// minProvincesPerMinor`, equal minor OW / tribe NW fair shares via the existing
/// [computeFairTargets], and enforces the orphan-continent rule.
///
/// Throws [FormatException] when faction minimums are unmet or when
/// `continentCount > gpCount` and `minorNationCount < (continentCount - gpCount)`.
///
/// SPEC/program/ga-setup-profile.md. Refs #3447.
GaSetupProfile buildGaSetupProfile({
  required List<String> selectedGreatPowerIds,
  int minorNationCount = kGaMinMinorNationCount,
  int tribeCount = kGaMinTribeCount,
  int? continentCount,
  int minProvincesPerMinor = 3,
  int numProvincesNewWorld = 12,
  int seed = 42,
}) {
  final gpCount = selectedGreatPowerIds.length;
  if (gpCount < 2) {
    throw FormatException(
      'selectedGreatPowerIds must contain at least 2 GPs (got $gpCount)',
    );
  }
  validateGaFactionMinimums(
    minorNationCount: minorNationCount,
    tribeCount: tribeCount,
  );
  if (minProvincesPerMinor < 1) {
    throw FormatException(
      'minProvincesPerMinor ($minProvincesPerMinor) must be at least 1',
    );
  }
  if (numProvincesNewWorld < tribeCount) {
    throw FormatException(
      'numProvincesNewWorld ($numProvincesNewWorld) must be at least '
      'tribeCount ($tribeCount) so every tribe owns at least one province',
    );
  }

  final resolvedContinentCount = continentCount ?? gpCount;
  if (resolvedContinentCount < 1) {
    throw FormatException(
      'continentCount ($resolvedContinentCount) must be at least 1',
    );
  }
  if (resolvedContinentCount > gpCount) {
    final unownedContinents = resolvedContinentCount - gpCount;
    if (minorNationCount < unownedContinents) {
      throw FormatException(
        'orphan continents: continentCount ($resolvedContinentCount) exceeds '
        'gpCount ($gpCount) by $unownedContinents, but minorNationCount '
        '($minorNationCount) is too small to cover every otherwise-unowned '
        'continent',
      );
    }
  }

  final numProvincesOldWorld =
      gpCount * kGpOwTargetPerGp + minorNationCount * minProvincesPerMinor;

  final minorOwTargets = _fairTargetCounts(
    factionCount: minorNationCount,
    total: minorNationCount * minProvincesPerMinor,
    prefix: 'minor',
  );
  final tribeNwTargets = _fairTargetCounts(
    factionCount: tribeCount,
    total: numProvincesNewWorld,
    prefix: 'tribe',
  );

  final setupConfig = GameSetupConfig(
    selectedGreatPowerIds: selectedGreatPowerIds,
    continentCount: resolvedContinentCount,
    minorNationCount: minorNationCount,
    tribeCount: tribeCount,
    numProvincesOldWorld: numProvincesOldWorld,
    numProvincesNewWorld: numProvincesNewWorld,
    minProvincesPerMinor: minProvincesPerMinor,
    seed: seed,
    humanGreatPowerSlotIndices: const <int>{},
  );

  return GaSetupProfile(
    setupConfig: setupConfig,
    gpOwTargetPerGp: kGpOwTargetPerGp,
    minorOwTargets: minorOwTargets,
    tribeNwTargets: tribeNwTargets,
  );
}

/// Equal fair split of [total] across [factionCount] factions, reusing
/// [computeFairTargets] with synthetic ids to preserve the ±1 tolerance.
List<int> _fairTargetCounts({
  required int factionCount,
  required int total,
  required String prefix,
}) {
  final ids = <String>[for (var i = 0; i < factionCount; i++) '$prefix-$i'];
  final targets = computeFairTargets(ids, total);
  return <int>[for (final id in ids) targets[id]!];
}
