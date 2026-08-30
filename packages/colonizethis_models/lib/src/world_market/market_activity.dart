/// Per-commodity market activity snapshot.
///
/// First-class library (Refs #4068 Slice C, #4571). SPEC/game/world-market.md.

import '../model_collection_equality.dart';
import '../model_json_numbers.dart';
import 'filled_deal.dart';
import 'market_activity_note.dart';

export 'market_activity_note.dart';

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
    if (deals.isNotEmpty) 'deals': [for (final d in deals) d.toJson()],
    if (notes.isNotEmpty) 'notes': [for (final n in notes) n.toJson()],
  };

  static MarketActivity fromJson(Map<String, dynamic> json) {
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
      totalBidQuantity: modelJsonIntOrZero(json['totalBidQuantity']),
      totalOfferQuantity: modelJsonIntOrZero(json['totalOfferQuantity']),
      filledQuantity: modelJsonIntOrZero(json['filledQuantity']),
      priceChangePercent: modelJsonDoubleOrZero(json['priceChangePercent']),
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
          modelListEquals(deals, other.deals) &&
          modelListEquals(notes, other.notes);

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
