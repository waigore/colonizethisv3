// SPEC/program/game-setup-pipeline.md — effective seed; shared by runInitGame and app GameService.

import 'setup_exceptions.dart';

/// Resolves the integer used for Old/New World map params, warp generation, naming, and
/// assignment perturbation base.
///
/// [configSeed] must be non-negative. **0** means “random at resolution time”: uses
/// [DateTime.now]. Any positive value is used as-is for reproducible runs.
int resolveEffectiveSetupSeed(int configSeed) {
  if (configSeed < 0) {
    throw SetupConfigConstraintException(
      code: 'invalid_setup_seed',
      details: 'config.seed must be >= 0 (got $configSeed)',
    );
  }
  return configSeed == 0 ? DateTime.now().millisecondsSinceEpoch : configSeed;
}
