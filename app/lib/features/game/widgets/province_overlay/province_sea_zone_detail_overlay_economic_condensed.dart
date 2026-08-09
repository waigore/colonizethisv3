import 'package:colonizethis_data/colonizethis_data.dart' show CommodityCatalog;

import 'package:colonizethis_models/colonizethis_models.dart'
    show ProvinceExtractionSnapshot;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../production/commodity_ui_helpers.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart' show ProvinceImprovableCommodityCount;

Widget extractionAvailableSubsection({
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

Widget extractionCondensedLine({
  required AppLocalizations l10n,
  required ProvinceExtractionSnapshot? snapshot,
  void Function(Iterable<String>?)? onHighlightTiles,
}) {
  if (snapshot == null || snapshot.byCommodity.isEmpty) {
    return overlayEmptyBodyDashText();
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
      commodityHoverSegment(
        tileKeys: totals.tileKeys,
        onHighlightTiles: onHighlightTiles,
        child: commoditySegmentRow(
          commodityId: commodity.id,
          quantityText: qtyText,
        ),
      ),
    );
    if (commodity.id == CommodityCatalog.grain.id &&
        snapshot.capitalGrainBonus > 0) {
      segments.add(
        Text(
          l10n.provinceOverlay_extractionCapitalGrainBonus(
            snapshot.capitalGrainBonus,
          ),
          style: TextStyle(color: EditorialMonoclePalette.muted),
        ),
      );
    }
  }
  if (segments.isEmpty) return overlayEmptyBodyDashText();
  final condensed = condensedCommodityWrap(segments);
  return snapshot.hasPartialYield
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            condensed,
            Text(
              l10n.provinceOverlay_extractionPartialReason,
              style: TextStyle(color: EditorialMonoclePalette.muted),
            ),
          ],
        )
      : condensed;
}

Widget availableCondensedLine({
  required AppLocalizations l10n,
  required Map<String, ProvinceImprovableCommodityCount> availableByCommodity,
  void Function(Iterable<String>?)? onHighlightTiles,
}) {
  if (availableByCommodity.isEmpty) return overlayEmptyBodyDashText();
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
      commodityHoverSegment(
        tileKeys: entry.tileKeys,
        onHighlightTiles: onHighlightTiles,
        child: commoditySegmentRow(
          commodityId: commodity.id,
          quantityText: qtyText,
        ),
      ),
    );
  }
  if (segments.isEmpty) return overlayEmptyBodyDashText();
  return condensedCommodityWrap(segments);
}

Widget condensedCommodityWrap(List<Widget> segments) {
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

Widget commoditySegmentRow({
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

Widget commodityHoverSegment({
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
