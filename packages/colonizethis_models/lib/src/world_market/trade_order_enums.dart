/// Trade order type and status enums.
///
/// First-class library (Refs #4571). SPEC/game/world-market.md.

import '../model_validation_exception.dart';

/// Buy or sell intent for a [TradeOrder].
enum TradeOrderType {
  bid,
  offer;

  String toJsonName() => name;

  static TradeOrderType fromJsonName(String value) {
    for (final t in TradeOrderType.values) {
      if (t.name == value) return t;
    }
    throw ModelValidationException.value(
      value,
      'value',
      'unknown TradeOrderType',
    );
  }
}

/// Outcome status for a [TradeOrder] after a market phase resolves.
enum TradeOrderStatus {
  pending,
  filled,
  partiallyFilled,
  unfilled,
  droppedInsufficientStockpile,
  droppedInsufficientCargo,
  rejected;

  String toJsonName() => name;

  static TradeOrderStatus fromJsonName(String value) {
    for (final s in TradeOrderStatus.values) {
      if (s.name == value) return s;
    }
    throw ModelValidationException.value(
      value,
      'value',
      'unknown TradeOrderStatus',
    );
  }
}
