// Committed gold families for the map treasury teaching popover (Refs #4560).
//
// SPEC: SPEC/ui/empire-overview.md § Treasury teaching surface.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

import '../technology/research_slot_preview.dart';
import '../technology/research_slot_preview_inputs.dart';

/// Committed gold family shown in the treasury details popover.
enum TreasuryCommittedSpendFamily {
  research,
  marketBids,
  grantAid,
  overtures,
  recruitWorkers,
  trainUnits,
  purchaseLand,
}

/// One non-zero committed gold line (player language via l10n).
class TreasuryCommittedSpendLine {
  const TreasuryCommittedSpendLine({
    required this.family,
    required this.amount,
  });

  final TreasuryCommittedSpendFamily family;

  /// Positive treasury spend already staged for Next turn.
  final int amount;
}

/// Read model of non-zero committed gold families for the human focus player.
class TreasuryCommittedSpendSnapshot {
  const TreasuryCommittedSpendSnapshot({this.lines = const []});

  final List<TreasuryCommittedSpendLine> lines;

  bool get isEmpty => lines.isEmpty;
}

/// Builds committed-gold lines from unresolved [orders] for [player].
///
/// Omits zero families. Research uses only occupied seats with actual spend
/// (`totalGoldSpent`) — never empty seats (UXD-001). Spies are never listed
/// as a family (UXD-002).
TreasuryCommittedSpendSnapshot computeTreasuryCommittedSpend({
  required Game game,
  required Player player,
  required Orders orders,
  ResourceRules? resourceRules,
}) {
  final rules = resourceRules ?? ResourceRules.defaultRules;
  final lines = <TreasuryCommittedSpendLine>[];

  final researchGold = computeResearchSlotsTurnPreview(
    player: player,
    occupiedSlots: occupiedResearchSlotPreviewInputs(
      game: game,
      player: player,
      currentOrders: orders,
    ),
  ).totalGoldSpent;
  _appendIfPositive(lines, TreasuryCommittedSpendFamily.research, researchGold);

  final bids = stagedBidTotalSpendByPlayer(
    orders: orders,
    playerId: player.id,
    game: game,
    resourceRules: rules,
  );
  _appendIfPositive(lines, TreasuryCommittedSpendFamily.marketBids, bids);

  final diplomatic =
      orders.diplomaticOrdersByPlayerId[player.id] ?? const <DiplomaticOrder>[];
  var grantTotal = 0;
  var overtureTotal = 0;
  for (final order in diplomatic) {
    if (order.type == DiplomaticOrderType.grantAid) {
      grantTotal += order.amount ?? grantAidDefaultAmount;
    } else if (order.type == DiplomaticOrderType.establishOverture) {
      overtureTotal += _overtureCost(order.overtureStage);
    }
  }
  _appendIfPositive(lines, TreasuryCommittedSpendFamily.grantAid, grantTotal);
  _appendIfPositive(
    lines,
    TreasuryCommittedSpendFamily.overtures,
    overtureTotal,
  );

  final recruits =
      orders.recruitWorkerOrdersByPlayerId[player.id] ??
      const <RecruitWorkerOrder>[];
  var recruitTotal = 0;
  for (final order in recruits) {
    recruitTotal +=
        WorkerActionEconomyCatalog.forTier(order.targetTier).treasuryCost;
  }
  _appendIfPositive(
    lines,
    TreasuryCommittedSpendFamily.recruitWorkers,
    recruitTotal,
  );

  final builds =
      orders.buildUnitOrdersByPlayerId[player.id] ?? const <BuildUnitOrder>[];
  var trainTotal = 0;
  for (final order in builds) {
    trainTotal += _buildUnitTreasuryCost(order.unitType);
  }
  _appendIfPositive(
    lines,
    TreasuryCommittedSpendFamily.trainUnits,
    trainTotal,
  );

  final works =
      orders.workOrdersByPlayerId[player.id] ?? const <WorkOrder>[];
  var purchaseTotal = 0;
  for (final order in works) {
    if (order.target != kWorkTargetPurchaseLand) {
      continue;
    }
    final resourceId = game.worldState.resourceAtTile(order.targetTileKey);
    if (resourceId == null || resourceId.isEmpty) {
      continue;
    }
    purchaseTotal += purchaseLandCost(resourceId);
  }
  _appendIfPositive(
    lines,
    TreasuryCommittedSpendFamily.purchaseLand,
    purchaseTotal,
  );

  return TreasuryCommittedSpendSnapshot(lines: lines);
}

void _appendIfPositive(
  List<TreasuryCommittedSpendLine> lines,
  TreasuryCommittedSpendFamily family,
  int amount,
) {
  if (amount <= 0) {
    return;
  }
  lines.add(TreasuryCommittedSpendLine(family: family, amount: amount));
}

int _overtureCost(OvertureStage? stage) {
  if (stage == OvertureStage.tradeConsulate) {
    return overtureConsulateCost;
  }
  if (stage == OvertureStage.embassy) {
    return overtureEmbassyCost;
  }
  return 0;
}

int _buildUnitTreasuryCost(String unitType) {
  final civilian = CivilianEconomyCatalog.byId[unitType];
  if (civilian != null) {
    return civilian.buildTreasuryCost;
  }
  final regiment = RegimentEconomyCatalog.byId[unitType];
  if (regiment != null) {
    return regiment.buildTreasuryCost;
  }
  final ship = ShipEconomyCatalog.byId[unitType];
  if (ship != null) {
    return ship.buildTreasuryCost;
  }
  return 0;
}
