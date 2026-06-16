/// Deterministic per-game and per-seat seeds for GA observer rounds.
/// SPEC/program/ga-runner.md. Refs #3439, #3488.

/// Per-game seed for 2-player evaluation rounds.
int deriveGameSeed(
  int masterSeed,
  int generation,
  int profileIndex,
  int gameIndex,
) =>
    masterSeed ^ (generation * 1000003) ^ (profileIndex * 9973) ^ (gameIndex * 101);

/// Salt XOR so 7-GP game seeds never collide with 2-player seeds for the same
/// tuple inputs.
const int _kSevenGpGameSalt = 0x7007007;

/// Per-game seed for 7-GP evaluation rounds.
int deriveSevenGpGameSeed(
  int masterSeed,
  int generation,
  int profileIndex,
  int gameIndex,
) =>
    deriveGameSeed(masterSeed, generation, profileIndex, gameIndex) ^
    _kSevenGpGameSalt;

/// Per-seat seed for randomized-AI opponent generation in 7-GP rosters.
int deriveSevenGpSeatSeed(
  int masterSeed,
  int generation,
  int subjectIndex,
  int seatIndex,
) =>
    masterSeed ^
    (generation * 1000003) ^
    (subjectIndex * 9973) ^
    (seatIndex * 1009) ^
    _kSevenGpGameSalt;

/// Salt XOR so the `random` opponent-selection shuffle seed never collides with
/// per-seat randomized-AI seeds for the same tuple inputs.
const int _kSevenGpSelectionSalt = 0x5E1EC7;

/// Seed for the deterministic `random` `seven_gp_opponent_selection` shuffle of
/// the prior-generation-winner pool. Independent of [deriveSevenGpSeatSeed] so
/// reordering prior winners does not perturb the randomized-AI fallback stream.
int deriveSevenGpSelectionSeed(
  int masterSeed,
  int generation,
  int subjectIndex,
) =>
    masterSeed ^
    (generation * 1000003) ^
    (subjectIndex * 9973) ^
    _kSevenGpSelectionSalt;
