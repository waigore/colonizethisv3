/// Injectable seam for the order-effects dry-run projection (Refs #3290 C2).
///
/// The concrete projector `projectOrderEffects`
/// (`lib/src/projections/order_projections.dart`) runs the turn resolver
/// (`resolveTurnForGame`) and therefore lives in the neutral `projections/`
/// core module, which sits *above* the `orders` domain in the package-split
/// DAG. The `orders` source tree (the future `colonizethis_orders` package)
/// must not import that core module, so `OrderEngine` accepts the projector as
/// an injected dependency instead (mirroring the existing injected
/// `validatorFactory`). The turn orchestrator and the app / ctdev /
/// sim-scenario consumers inject the concrete `projectOrderEffects`.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'projected_effects.dart';

export 'projected_effects.dart';

/// Signature of the order-effects projector injected into `OrderEngine`.
///
/// Matches `projectOrderEffects` in
/// `lib/src/projections/order_projections.dart`. SPEC/program/order-engine.md
/// § Injected projector seam, SPEC/program/order-projections.md.
typedef OrderEffectsProjector =
    ProjectedEffects Function({
      required Game game,
      required Orders orders,
      required MapTopology topology,
      required Map<String, TileMapResult> tileMapByRegion,
      required String playerId,
      List<AssignedRecipe> defaultAssignments,
    });
