/// Sentinels for squared-distance and score scans in tile map generation.
/// [kUnsetSquaredDistanceInt31] means “no candidate chosen yet”.
const int kUnsetSquaredDistanceInt31 = 0x7fffffff;

/// Minimum score sentinel when maximizing land-seed placement scores.
const int kMinLandSeedScoreSentinel = -kUnsetSquaredDistanceInt31;
