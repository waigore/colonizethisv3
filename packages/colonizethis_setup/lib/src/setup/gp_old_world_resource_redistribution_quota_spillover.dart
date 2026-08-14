// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.redist).
// Quota spillover pool: cap unreachable targets and redistribute surplus
// (Refs #4349 Slice B).

import 'package:colonizethis_data/colonizethis_data.dart';

import 'gp_old_world_resource_redistribution_tile_scans.dart';
import 'gp_old_world_resource_redistribution_types.dart';

/// Caps targets to reachable counts; returns surplus moved into the pool.
int accumulateSpilloverPool({
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required Resource r,
  required ResourceRules resourceRules,
  required List<GpOwTileInvEntry> inventory,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  var pool = 0;
  for (final gp in shuffled) {
    final tgt = targets[gp] ?? 0;
    final pl = placed[gp] ?? 0;
    final deficit = tgt - pl;
    if (deficit <= 0) continue;
    final eg = eligibleEmptyCountForGp(
      inventory: inventory,
      r: r,
      rules: resourceRules,
      gp: gp,
      forbidden: forbidden,
      used: used,
    );
    final maxTarget = pl + eg;
    if (tgt <= maxTarget) continue;
    pool += tgt - maxTarget;
    targets[gp] = maxTarget;
  }
  return pool;
}

({int newPool, bool anyIncrement}) applyOneQuotaPoolRound({
  required int pool,
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required Resource r,
  required ResourceRules resourceRules,
  required List<GpOwTileInvEntry> inventory,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  var p = pool;
  var moved = false;
  for (final h in shuffled) {
    if (p <= 0) break;
    final pl = placed[h] ?? 0;
    final tgt = targets[h] ?? 0;
    final eg = eligibleEmptyCountForGp(
      inventory: inventory,
      r: r,
      rules: resourceRules,
      gp: h,
      forbidden: forbidden,
      used: used,
    );
    final maxTarget = pl + eg;
    if (tgt >= maxTarget) continue;
    targets[h] = tgt + 1;
    p--;
    moved = true;
  }
  return (newPool: p, anyIncrement: moved);
}

void distributeQuotaPool({
  required int initialPool,
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required Resource r,
  required ResourceRules resourceRules,
  required List<GpOwTileInvEntry> inventory,
  required Set<String> forbidden,
  required Set<String> used,
  required int sumPlaced,
  required int nR,
}) {
  var pool = initialPool;
  while (pool > 0) {
    final round = applyOneQuotaPoolRound(
      pool: pool,
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      r: r,
      resourceRules: resourceRules,
      inventory: inventory,
      forbidden: forbidden,
      used: used,
    );
    pool = round.newPool;
    if (!round.anyIncrement) {
      throw GpOldWorldResourceRedistributionInfeasibleException(
        resource: r,
        details:
            'cannot distribute quota pool=$pool sumPlaced=$sumPlaced nR=$nR',
      );
    }
  }
}
