// SPEC/ui/game-initializing.md — per-attempt GameSetupConfig.seed after Retry.

/// Seed stored on [GameSetupConfig] for new-game setup attempt [attemptIndex]
/// (0 = first try, 1 = first retry, …), given the seed the user confirmed in the
/// leader dialog ([dialogChosenSeed], always `>= 0`).
///
/// When [dialogChosenSeed] is **0** (“random”), every attempt uses **0** again so
/// effective seed resolution (time-based at init) runs fresh each time.
/// When non-zero **K**, attempt **N** uses **K + N** so retries perturb the pipeline.
int newGameSetupConfigSeedForAttempt({
  required int dialogChosenSeed,
  required int attemptIndex,
}) {
  assert(attemptIndex >= 0, 'attemptIndex must be non-negative');
  assert(dialogChosenSeed >= 0, 'dialogChosenSeed must be non-negative');
  return dialogChosenSeed == 0 ? 0 : dialogChosenSeed + attemptIndex;
}
