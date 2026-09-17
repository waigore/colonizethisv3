/// Ids-only payoff tokens on `work_order_completed` (Refs #4778).
///
/// SPEC/program/game-events.md. UI formats display names; never store copy here.
abstract final class WorkOrderPayoffKind {
  static const fullyVisible = 'fully_visible';
  static const yieldRaise = 'yield_raise';
  static const roadLimit = 'road_limit';
  static const townLimit = 'town_limit';
  static const unbound = 'unbound';
  static const bindsCapital = 'binds_capital';
  static const portPresent = 'port_present';
  static const railroadPresent = 'railroad_present';
  static const workshopsStart = 'workshops_start';
  static const workshopsPause = 'workshops_pause';
  static const workshopsResume = 'workshops_resume';
  static const fortOpenField = 'fort_open_field';
  static const fortWood = 'fort_wood';
  static const fortStone = 'fort_stone';
  static const fortModern = 'fort_modern';
  static const purchaseTradeable = 'purchase_tradeable';
  static const purchaseRiches = 'purchase_riches';
}
