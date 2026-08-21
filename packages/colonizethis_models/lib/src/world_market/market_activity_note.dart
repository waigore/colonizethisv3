/// Market activity audit note types.
///
/// First-class library (Refs #4571). SPEC/game/world-market.md;
/// SPEC/program/world-market-resolution.md.

import '../model_validation_exception.dart';
import '../stockpile.dart';

/// Categorical reason recorded on a [MarketActivityNote] when the world
/// market phase drops a carry-forward order or otherwise emits an
/// audit-grade event for the Deal Book / observer tooling per
/// `SPEC/program/world-market-resolution.md` § Step A Gather (Step A.3) and
/// § Step F Activity rollup.
enum MarketActivityNoteKind {
  /// Carry-forward offer dropped at start of phase because the submitter's
  /// current stockpile for the order's commodity is below the order's
  /// quantity (`SPEC/game/world-market.md` § Order persistence
  /// "Carry-forward drop on stockpile shortfall").
  carryForwardDroppedStockpileInsufficient,

  /// Carry-forward bid dropped at start of phase because the submitter's
  /// current trade cargo capacity is below the order's quantity
  /// (`SPEC/game/world-market.md` § Order persistence
  /// "Carry-forward drop on cargo shortfall").
  carryForwardDroppedCargoInsufficient,

  /// Bid partially filled (or fully suppressed) inside the deal matcher
  /// because the buyer's start-of-phase treasury budget could not cover
  /// the bid's full notional at the matched price. Recorded once per
  /// truncated bid per `SPEC/program/world-market-resolution.md` § Step C
  /// (treasury clamp, Refs #3115). The note's `quantity` is the original
  /// submitted bid quantity; the residual carry-forward is preserved in
  /// `DealMatchResult.unfilledBidsByFactionId` for next-turn re-entry.
  bidPartialFillTreasuryInsufficient;

  String toJsonName() => name;

  static MarketActivityNoteKind fromJsonName(String value) {
    for (final k in MarketActivityNoteKind.values) {
      if (k.name == value) return k;
    }
    throw ModelValidationException.value(
      value,
      'value',
      'unknown MarketActivityNoteKind',
    );
  }
}

/// Single audit-grade event attached to a [MarketActivity] entry for the
/// commodity the event relates to. Used by the Deal Book UI and the
/// observer/AI traces to explain dropped carry-forwards and other
/// phase-internal decisions that do not produce a `FilledDeal` but do
/// affect the submitter's order book.
///
/// Notes are pure value objects: immutable, JSON-serializable, value-equal.
class MarketActivityNote {
  const MarketActivityNote({
    required this.kind,
    required this.factionId,
    required this.commodityId,
    required this.quantity,
  });

  /// Categorical reason for the note.
  final MarketActivityNoteKind kind;

  /// Faction id whose order was affected (e.g. the dropped carry-forward
  /// submitter). Always non-empty for the carry-forward drop kinds.
  final String factionId;

  /// Commodity id the note is scoped to. Matches the commodity key the
  /// note will be recorded under inside `MarketActivity.notes`.
  final CommodityId commodityId;

  /// Affected quantity in commodity units. For drop kinds this is the
  /// quantity that did **not** survive into matching (i.e. the original
  /// carry-forward quantity).
  final int quantity;

  Map<String, dynamic> toJson() => {
    'kind': kind.toJsonName(),
    'factionId': factionId,
    'commodityId': commodityId,
    'quantity': quantity,
  };

  static MarketActivityNote fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind'];
    if (kindRaw is! String) {
      throw ModelValidationException.value(
        kindRaw,
        'kind',
        'MarketActivityNote.fromJson: kind must be String',
      );
    }
    final factionRaw = json['factionId'];
    if (factionRaw is! String) {
      throw ModelValidationException.value(
        factionRaw,
        'factionId',
        'MarketActivityNote.fromJson: factionId must be String',
      );
    }
    final commodityRaw = json['commodityId'];
    if (commodityRaw is! String) {
      throw ModelValidationException.value(
        commodityRaw,
        'commodityId',
        'MarketActivityNote.fromJson: commodityId must be String',
      );
    }
    final qtyRaw = json['quantity'];
    final qty = qtyRaw is int ? qtyRaw : int.tryParse(qtyRaw?.toString() ?? '');
    if (qty == null) {
      throw ModelValidationException.value(
        qtyRaw,
        'quantity',
        'MarketActivityNote.fromJson: quantity must be int',
      );
    }
    return MarketActivityNote(
      kind: MarketActivityNoteKind.fromJsonName(kindRaw),
      factionId: factionRaw,
      commodityId: commodityRaw,
      quantity: qty,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketActivityNote &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          factionId == other.factionId &&
          commodityId == other.commodityId &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(kind, factionId, commodityId, quantity);

  @override
  String toString() =>
      'MarketActivityNote(${kind.name} faction=$factionId '
      'commodity=$commodityId qty=$quantity)';
}
