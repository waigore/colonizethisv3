// SPDX-License-Identifier: Apache-2.0

import 'package:colonizethis_models/colonizethis_models.dart';

/// Deterministic 31-bit LCG RNG (glibc multipliers) for replay-stable rolls.
class DeterministicRng {
  DeterministicRng(this._seed);

  int _seed;

  int nextInt(int max) {
    if (max <= 0) return 0;
    _seed =
        (_seed * kDeterministicLcgMultiplierGlibc +
            kDeterministicLcgIncrementGlibc) &
        kDeterministicLcg31Mask;
    return _seed % max;
  }
}
