/// glibc-style linear congruential generator step (mod 2^31) for deterministic
/// sub-seeds. Used with [kDeterministicLcg31Mask].
const int kDeterministicLcgMultiplierGlibc = 1103515245;
const int kDeterministicLcgIncrementGlibc = 12345;

/// Bit mask keeping the low 31 bits non-negative (LCG and many mix steps).
const int kDeterministicLcg31Mask = 0x7fffffff;
