// SPDX-License-Identifier: Apache-2.0

/// Poisson sampling and strength-weighted casualty selection for probabilistic
/// combat. SPEC/program/sim-combat.md.
library;

import 'dart:math';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'military_strength.dart';

int poissonSample(double lambda, Random rng) {
  if (lambda <= 0) return 0;
  final L = exp(-lambda);
  var k = 0;
  var p = 1.0;
  do {
    k++;
    p *= rng.nextDouble();
    if (p <= 0) return k - 1;
  } while (p > L);
  return k - 1;
}

/// Select [n] casualties using inverse-strength weighting (stronger = less likely).
List<String> selectCasualtiesWeighted(
  List<Unit> units,
  int n,
  int effectiveEra,
  Random rng,
) {
  if (n <= 0 || units.isEmpty) return [];
  if (n >= units.length) return units.map((u) => u.id).toList();

  final weights = <double>[];
  for (final u in units) {
    final s = unitStrength(u, effectiveEra);
    weights.add(1.0 / (s + 0.1));
  }
  final ids = units.map((u) => u.id).toList();
  final alive = List<bool>.filled(ids.length, true);
  final chosen = <String>[];

  for (var i = 0; i < n; i++) {
    var total = 0.0;
    for (var j = 0; j < weights.length; j++) {
      if (alive[j]) total += weights[j];
    }
    if (total <= 0) break;
    var r = rng.nextDouble() * total;
    for (var j = 0; j < weights.length; j++) {
      if (!alive[j]) continue;
      r -= weights[j];
      if (r <= 0) {
        chosen.add(ids[j]);
        alive[j] = false;
        break;
      }
    }
  }
  return chosen;
}
