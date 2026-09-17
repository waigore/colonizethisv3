import 'package:colonizethis_models/colonizethis_models.dart';

/// Chrome-local work-target ids for feed copy (Refs #4778).
///
/// Declared as fields so `repo.work_target_constants` stays green without a
/// chrome → orders/logic dependency. Values match `kWorkTarget*` in orders.
abstract final class EventFeedWorkTargets {
  static const prospect = 'prospect';
  static const explore = 'explore';
  static const buildImprovement = 'build_improvement';
  static const upgradeTown = 'upgrade_town';
  static const buildRoad = 'build_road';
  static const buildPort = 'build_port';
  static const buildRail = 'build_rail';
  static const buildFort = 'build_fort';
  static const purchaseLand = 'purchase_land';
}

/// Past-tense payoff clause for civilian work-complete feed rows (Refs #4778).
String workOrderCompletedPayoffClause({
  required String workTargetLabel,
  String? workTarget,
  String? prospectFoundDisplayName,
  String? payoffKind,
  String? payoffCommodityDisplayName,
  int? payoffLevel,
}) {
  if (workTarget == EventFeedWorkTargets.prospect) {
    final found =
        prospectFoundDisplayName == null || prospectFoundDisplayName.isEmpty
        ? 'no mineral'
        : prospectFoundDisplayName;
    return 'Prospect found $found';
  }
  final good = _namedGood(payoffCommodityDisplayName);
  return switch (workTarget) {
    EventFeedWorkTargets.explore => 'This province is now fully visible.',
    EventFeedWorkTargets.buildImprovement => _improveClause(payoffKind, good),
    EventFeedWorkTargets.upgradeTown => _townClause(payoffKind, payoffLevel),
    EventFeedWorkTargets.buildRoad => _roadClause(payoffKind, good),
    EventFeedWorkTargets.buildPort => 'This coast now has a port.',
    EventFeedWorkTargets.buildRail => _railClause(payoffKind, good),
    EventFeedWorkTargets.buildFort => _fortClause(payoffKind, payoffLevel),
    EventFeedWorkTargets.purchaseLand => _purchaseClause(payoffKind, good),
    _ => '$workTargetLabel finished!',
  };
}

String? _namedGood(String? displayName) {
  if (displayName == null || displayName.isEmpty) return null;
  return displayName;
}

String _improveClause(String? kind, String? good) {
  final named = good ?? 'goods';
  return switch (kind) {
    WorkOrderPayoffKind.roadLimit =>
      'The road still limits what $named arrives.',
    WorkOrderPayoffKind.townLimit =>
      'Town development still limits what $named arrives.',
    WorkOrderPayoffKind.unbound => 'This tile is still unbound.',
    _ => 'This tile now sends $named if still linked.',
  };
}

String _townClause(String? kind, int? level) {
  final token = kind ?? _townKindForLevel(level);
  return switch (token) {
    WorkOrderPayoffKind.workshopsPause => 'Town workshops pause until level 4.',
    WorkOrderPayoffKind.workshopsResume =>
      'Town workshops resume at double the level-2 rate.',
    _ => 'Town workshops now start.',
  };
}

String? _townKindForLevel(int? level) {
  if (level == null) return null;
  return switch (level) {
    <= 1 => WorkOrderPayoffKind.workshopsStart,
    2 => WorkOrderPayoffKind.workshopsPause,
    _ => WorkOrderPayoffKind.workshopsResume,
  };
}

String _roadClause(String? kind, String? good) {
  if (kind == WorkOrderPayoffKind.unbound) {
    return 'This tile is still unbound.';
  }
  if (kind == WorkOrderPayoffKind.yieldRaise && good != null) {
    return 'This tile now sends $good if still linked.';
  }
  return 'This tile is now bound to the capital.';
}

String _railClause(String? kind, String? good) {
  if (kind == WorkOrderPayoffKind.bindsCapital) {
    return 'This tile is now bound to the capital.';
  }
  if (kind == WorkOrderPayoffKind.yieldRaise && good != null) {
    return 'This tile now sends $good if still linked.';
  }
  return 'A railroad now stands on this tile.';
}

String _fortClause(String? kind, int? level) {
  final token = kind ?? _fortKindForLevel(level);
  return switch (token) {
    WorkOrderPayoffKind.fortOpenField => 'Siege posture is now open field.',
    WorkOrderPayoffKind.fortStone => 'Siege posture is now stone.',
    WorkOrderPayoffKind.fortModern => 'Siege posture is now modern.',
    _ => 'Siege posture is now wood.',
  };
}

String? _fortKindForLevel(int? level) {
  if (level == null) return null;
  return switch (level) {
    0 => WorkOrderPayoffKind.fortOpenField,
    1 => WorkOrderPayoffKind.fortWood,
    2 => WorkOrderPayoffKind.fortStone,
    _ => WorkOrderPayoffKind.fortModern,
  };
}

String _purchaseClause(String? kind, String? good) {
  if (kind == WorkOrderPayoffKind.purchaseRiches) {
    final what = good == null
        ? 'Riches from this tile'
        : '$good from this tile';
    return '$what now go to your treasury. The land stays the court’s.';
  }
  if (good != null) {
    return '$good still sells as that court’s. First bid and gold now start. '
        'The land stays the court’s.';
  }
  return 'First bid and gold on tradeable sales now start. '
      'The land stays the court’s.';
}
