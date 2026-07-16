part of 'trade_screen.dart';

/// Public Deal Book keys/literals for the trade screen.
/// Tests and Deal Book UI parts use this type directly (Refs #4035 trade API collapse).
abstract final class TradeScreenDealBookKeys {
  TradeScreenDealBookKeys._();

  /// Stable widget key for the Deal Book tab body. Pin point for widget
  /// tests asserting the Deal Book tab body is present in the tab
  /// strip's `IndexedStack` (visible when the Deal Book tab is selected
  /// after the user taps the Deal Book label). Refs #2993 E6 swapped
  /// the placeholder for `_DealBookTabContent` — the key is intentionally
  /// stable so existing tab-switch tests keep pinning the same body root.
  static const Key dealBookTabBodyKey =
      ValueKey<String>('tradeScreenDealBookTabBody');

  /// Stable widget key for the root of the live Deal Book ledger content
  /// (Refs #2993 E6). Sits directly under `dealBookTabBodyKey` and pins
  /// the two-panel layout so widget tests can scope queries.
  static const Key dealBookContentKey =
      ValueKey<String>('tradeScreenDealBookContent');

  /// Side identifier used to scope per-row Deal Book keys to the bids
  /// panel (commodities the player **bought**).
  static const String dealBookSideBids = 'bids';

  /// Side identifier used to scope per-row Deal Book keys to the offers
  /// panel (commodities the player **sold**).
  static const String dealBookSideOffers = 'offers';

  /// Stable widget key for the Deal Book bids panel container
  /// (Refs #2993 E6).
  static const Key dealBookBidsPanelKey =
      ValueKey<String>('tradeScreenDealBookBidsPanel');

  /// Stable widget key for the Deal Book offers panel container
  /// (Refs #2993 E6).
  static const Key dealBookOffersPanelKey =
      ValueKey<String>('tradeScreenDealBookOffersPanel');

  /// Stable widget key for the Deal Book bids panel treasury-totals row
  /// (`Total spent: N`). Always mounted under the bids panel even when
  /// `filledTotal == 0` so widget tests can pin the totals affordance.
  static const Key dealBookBidsTotalsKey =
      ValueKey<String>('tradeScreenDealBookBidsTotals');

  /// Stable widget key for the Deal Book offers panel treasury-totals
  /// row (`Total received: N`).
  static const Key dealBookOffersTotalsKey =
      ValueKey<String>('tradeScreenDealBookOffersTotals');

  /// Stable widget key for the Deal Book bids panel empty-state copy.
  /// Mounted only when the player has zero filled bids **and** zero
  /// carry-forward bids for the resolved turn; absent otherwise.
  static const Key dealBookBidsEmptyKey =
      ValueKey<String>('tradeScreenDealBookBidsEmpty');

  /// Stable widget key for the Deal Book offers panel empty-state copy.
  /// Mounted only when the player has zero filled sales **and** zero
  /// carry-forward offers for the resolved turn; absent otherwise.
  static const Key dealBookOffersEmptyKey =
      ValueKey<String>('tradeScreenDealBookOffersEmpty');

  /// Per-row Deal Book key for a filled deal row, scoped by `side`
  /// (`dealBookSideBids` or `dealBookSideOffers`) and the row's
  /// zero-based index inside the per-side filled-deals list. Lets widget
  /// tests pin a specific filled row without coupling to text matching.
  static Key dealBookFilledRowKey(String side, int index) =>
      ValueKey<String>('tradeScreenDealBookFilledRow:$side:$index');

  /// Per-row Deal Book key for an unfilled (carry-forward) order row,
  /// scoped by `side` and zero-based index.
  static Key dealBookUnfilledRowKey(String side, int index) =>
      ValueKey<String>('tradeScreenDealBookUnfilledRow:$side:$index');

  /// Minimum viewport width (logical px) above which the Deal Book
  /// renders its two panels side-by-side. Below this threshold the
  /// panels stack vertically so the 320 dp minimum viewport stays
  /// overflow-safe per `SPEC/ui/mobile-adaptation.md` § 7.
  static const double dealBookTwoPanelMinWidth = 600;

  /// Localized title for the Deal Book bids panel — the player's
  /// previous-turn buying activity (filled buys + carry-forward bids).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookBidsPanelTitle = 'Your bids';

  /// Localized title for the Deal Book offers panel — the player's
  /// previous-turn selling activity (filled sales + carry-forward
  /// offers).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookOffersPanelTitle = 'Your offers';

  /// Localized section heading for filled rows inside a Deal Book panel.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookFilledHeading = 'Filled';

  /// Localized section heading for carry-forward (unfilled) rows inside
  /// a Deal Book panel.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookUnfilledHeading = 'Unfilled (carry-forward)';

  /// Localized empty-state copy for the bids panel when the player has
  /// neither filled bids nor carry-forward bids for the resolved turn.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookBidsEmptyText =
      'No bids placed last turn.';

  /// Localized empty-state copy for the offers panel when the player
  /// has neither filled sales nor carry-forward offers for the resolved
  /// turn.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookOffersEmptyText =
      'No offers placed last turn.';

  /// Localized totals label for the bids panel (treasury spent on
  /// filled buys this turn — carry-forwards excluded because they have
  /// not cleared).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookTotalSpentLabel = 'Total spent';

  /// Localized totals label for the offers panel (treasury received
  /// from filled sales this turn — carry-forwards excluded).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookTotalReceivedLabel = 'Total received';

  /// Formats a filled-deal unit price for Deal Book rows (Refs #3093).
  ///
  /// `FilledDeal.pricePerUnit` may still be a legacy `double` on older
  /// saves; display uses `floor` so the readout matches integer market
  /// prices per `SPEC/game/world-market.md` § Price discovery.
  static String formatFilledDealUnitPrice(double pricePerUnit) =>
      pricePerUnit.floor().toString();

  /// Localized empty-state copy rendered inside a Deal Book panel's
  /// **Filled** section when the player has no filled rows on that side
  /// (but does have carry-forwards, so the panel itself is non-empty).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookFilledEmptyText = 'No deals filled this turn.';

  /// Localized empty-state copy rendered inside a Deal Book panel's
  /// **Unfilled** section when the player has no carry-forward orders
  /// on that side (but does have filled rows, so the panel itself is
  /// non-empty).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookUnfilledEmptyText =
      'No orders carrying forward.';

  /// Tab label for the Deal Book tab (previous-turn ledger). SPEC §
  /// Layout / wireframe pins the literal `"Deal Book"`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookTabLabel = 'Deal Book';
}
