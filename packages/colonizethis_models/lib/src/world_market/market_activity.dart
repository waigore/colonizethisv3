part of '../world_market.dart';

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
    final qty = qtyRaw is int
        ? qtyRaw
        : int.tryParse(qtyRaw?.toString() ?? '');
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

/// Per-commodity activity snapshot for the previous market turn.
///
/// `totalBidQuantity` and `totalOfferQuantity` count only newly-submitted
/// quantities for the resolved turn (carry-forwards excluded), matching the
/// price discovery aggregation contract in
/// `SPEC/game/world-market.md` § Price discovery.
///
/// `deals` carries the per-commodity sequence of [FilledDeal] entries that
/// the deal matcher produced for the resolved turn (see
/// `SPEC/program/world-market-resolution.md` § Step F Activity rollup and
/// § Data model). The Deal Book UI (`#2993` E6) consumes this list,
/// filtered by buyer/seller faction id, to render the player's ledger.
/// The list is **always** stored unmodifiable; callers must not mutate it
/// in place.
///
/// `notes` carries audit-grade events scoped to this commodity for the
/// resolved turn (currently: dropped carry-forwards per
/// `SPEC/program/world-market-resolution.md` § Step A Gather). The list is
/// **always** stored unmodifiable; callers must not mutate it in place.
class MarketActivity {
  const MarketActivity({
    this.totalBidQuantity = 0,
    this.totalOfferQuantity = 0,
    this.filledQuantity = 0,
    this.priceChangePercent = 0.0,
    this.deals = const <FilledDeal>[],
    this.notes = const <MarketActivityNote>[],
  });

  final int totalBidQuantity;
  final int totalOfferQuantity;
  final int filledQuantity;
  final double priceChangePercent;
  final List<FilledDeal> deals;
  final List<MarketActivityNote> notes;

  static const empty = MarketActivity();

  Map<String, dynamic> toJson() => {
    'totalBidQuantity': totalBidQuantity,
    'totalOfferQuantity': totalOfferQuantity,
    'filledQuantity': filledQuantity,
    'priceChangePercent': priceChangePercent,
    if (deals.isNotEmpty)
      'deals': [for (final d in deals) d.toJson()],
    if (notes.isNotEmpty)
      'notes': [for (final n in notes) n.toJson()],
  };

  static MarketActivity fromJson(Map<String, dynamic> json) {
    int intOrZero(Object? v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double doubleOrZero(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    final dealsRaw = json['deals'];
    final deals = <FilledDeal>[];
    if (dealsRaw is List<dynamic>) {
      for (final entry in dealsRaw) {
        if (entry is Map<dynamic, dynamic>) {
          deals.add(FilledDeal.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }

    final notesRaw = json['notes'];
    final notes = <MarketActivityNote>[];
    if (notesRaw is List<dynamic>) {
      for (final entry in notesRaw) {
        if (entry is Map<dynamic, dynamic>) {
          notes.add(
            MarketActivityNote.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    return MarketActivity(
      totalBidQuantity: intOrZero(json['totalBidQuantity']),
      totalOfferQuantity: intOrZero(json['totalOfferQuantity']),
      filledQuantity: intOrZero(json['filledQuantity']),
      priceChangePercent: doubleOrZero(json['priceChangePercent']),
      deals: deals.isEmpty
          ? const <FilledDeal>[]
          : List<FilledDeal>.unmodifiable(deals),
      notes: notes.isEmpty
          ? const <MarketActivityNote>[]
          : List<MarketActivityNote>.unmodifiable(notes),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketActivity &&
          runtimeType == other.runtimeType &&
          totalBidQuantity == other.totalBidQuantity &&
          totalOfferQuantity == other.totalOfferQuantity &&
          filledQuantity == other.filledQuantity &&
          priceChangePercent == other.priceChangePercent &&
          _listEquals(deals, other.deals) &&
          _listEquals(notes, other.notes);

  @override
  int get hashCode => Object.hash(
    totalBidQuantity,
    totalOfferQuantity,
    filledQuantity,
    priceChangePercent,
    Object.hashAll(deals),
    Object.hashAll(notes),
  );
}
