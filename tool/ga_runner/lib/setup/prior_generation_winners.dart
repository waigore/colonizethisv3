import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'seven_gp_opponent_roster.dart';

/// Loads per-generation best profiles from completed generations before
/// [beforeGeneration]. Refs #3488.
List<PriorGenerationWinner> loadPriorGenerationWinners({
  required String runDir,
  required int beforeGeneration,
}) {
  final winners = <PriorGenerationWinner>[];
  for (var gen = 0; gen < beforeGeneration; gen++) {
    final genLabel = gen.toString().padLeft(3, '0');
    final genDir = Directory('$runDir/gen-$genLabel');
    if (!genDir.existsSync()) continue;
    final fitnessFile = File('${genDir.path}/fitness.json');
    final bestProfileFile = File('${genDir.path}/best-profile.json');
    if (!fitnessFile.existsSync() || !bestProfileFile.existsSync()) continue;
    final fitnessMap = jsonDecode(fitnessFile.readAsStringSync());
    if (fitnessMap is! Map<String, dynamic> || fitnessMap.isEmpty) continue;
    final bestEntry = fitnessMap.entries.reduce(
      (a, b) => (a.value as num) >= (b.value as num) ? a : b,
    );
    final profileDecoded = jsonDecode(bestProfileFile.readAsStringSync());
    if (profileDecoded is! Map<String, dynamic>) continue;
    winners.add(
      PriorGenerationWinner(
        profile: AiProfile.fromJson(profileDecoded),
        fitness: (bestEntry.value as num).toDouble(),
        generation: gen,
      ),
    );
  }
  return winners;
}
