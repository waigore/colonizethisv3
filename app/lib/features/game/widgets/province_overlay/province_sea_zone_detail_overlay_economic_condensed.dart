part of 'province_sea_zone_detail_overlay.dart';

Widget _extractionAvailableSubsection({
  required String heading,
  required Widget child,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: CtSpacing.m / 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          heading,
          style: TextStyle(
            color: EditorialMonoclePalette.fg,
            fontWeight: FontWeight.bold,
          ),
        ),
        child,
      ],
    ),
  );
}

Widget _extractionCondensedLine({
  required AppLocalizations l10n,
  required ProvinceExtractionSnapshot? snapshot,
  void Function(Iterable<String>?)? onHighlightTiles,
}) {
  if (snapshot == null || snapshot.byCommodity.isEmpty) {
    return _emptyBodyDashText();
  }
  final segments = <Widget>[];
  for (final commodity in CommodityCatalog.all) {
    final totals = snapshot.byCommodity[commodity.id];
    if (totals == null) continue;
    if (totals.effective == 0 && totals.full == 0) continue;
    final name = commodityDisplayName(l10n, commodity.id);
    final qtyText = totals.effective < totals.full
        ? l10n.provinceOverlay_extractionQuantityPartial(
            totals.effective,
            totals.full,
            name,
          )
        : l10n.provinceOverlay_extractionQuantity(totals.effective, name);
    if (segments.isNotEmpty) {
      segments.add(
        Text(', ', style: TextStyle(color: EditorialMonoclePalette.fg)),
      );
    }
    segments.add(
      _commodityHoverSegment(
        tileKeys: totals.tileKeys,
        onHighlightTiles: onHighlightTiles,
        child: _commoditySegmentRow(
          commodityId: commodity.id,
          quantityText: qtyText,
        ),
      ),
    );
    // Capital grain bonus is a special non-tile case — muted annotation,
    // not a hover-highlight target (Refs #4064).
    if (commodity.id == CommodityCatalog.grain.id &&
        snapshot.capitalGrainBonus > 0) {
      segments.add(
        Text(
          ' ${l10n.provinceOverlay_extractionCapitalGrainBonus(snapshot.capitalGrainBonus)}',
          style: TextStyle(color: EditorialMonoclePalette.muted),
        ),
      );
    }
  }
  if (segments.isEmpty) return _emptyBodyDashText();
  return _condensedCommodityWrap(segments);
}

Widget _availableCondensedLine({
  required AppLocalizations l10n,
  required Map<String, ProvinceImprovableCommodityCount> availableByCommodity,
  void Function(Iterable<String>?)? onHighlightTiles,
}) {
  if (availableByCommodity.isEmpty) return _emptyBodyDashText();
  final segments = <Widget>[];
  for (final commodity in CommodityCatalog.all) {
    final entry = availableByCommodity[commodity.id];
    if (entry == null || entry.count <= 0) continue;
    final name = commodityDisplayName(l10n, commodity.id);
    final qtyText = l10n.provinceOverlay_availableTileCount(entry.count, name);
    if (segments.isNotEmpty) {
      segments.add(
        Text(', ', style: TextStyle(color: EditorialMonoclePalette.fg)),
      );
    }
    segments.add(
      _commodityHoverSegment(
        tileKeys: entry.tileKeys,
        onHighlightTiles: onHighlightTiles,
        child: _commoditySegmentRow(
          commodityId: commodity.id,
          quantityText: qtyText,
        ),
      ),
    );
  }
  if (segments.isEmpty) return _emptyBodyDashText();
  return _condensedCommodityWrap(segments);
}

/// Wraps commodity chips to panel max width (wrap-not-truncate). Refs #4002.
Widget _condensedCommodityWrap(List<Widget> segments) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : double.infinity;
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final segment in segments)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: segment,
            ),
        ],
      );
    },
  );
}

Widget _commoditySegmentRow({
  required String commodityId,
  required String quantityText,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ResourceIcon(commodityId: commodityId, size: 20),
      const SizedBox(width: CtSpacing.m / 4),
      Flexible(
        child: Text(
          quantityText,
          style: TextStyle(color: EditorialMonoclePalette.fg),
          softWrap: true,
        ),
      ),
    ],
  );
}

Widget _commodityHoverSegment({
  required List<String> tileKeys,
  required void Function(Iterable<String>?)? onHighlightTiles,
  required Widget child,
}) {
  if (onHighlightTiles == null || tileKeys.isEmpty) return child;
  return MouseRegion(
    onEnter: (_) => onHighlightTiles(tileKeys),
    onExit: (_) => onHighlightTiles(null),
    child: child,
  );
}
