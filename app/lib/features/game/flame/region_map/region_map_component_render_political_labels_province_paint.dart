
part of 'region_map_component.dart';

extension _CtRegionMapRenderPoliticalLabelsProvincePaint
    on CtRegionMapComponent {
  void _paintProvinceNames(Canvas canvas) {
    _ensureProvinceLabelCache();
    final labels = session.provinceLabelsCached;
    if (labels == null || labels.isEmpty) {
      return;
    }

    final invZ = 1.0 / cameraZoom.clamp(0.25, 4.0);
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: RegionMapPalette.provinceLabelFontSizePx,
      fontWeight: FontWeight.w600,
      shadows: <Shadow>[
        Shadow(
          blurRadius: 2,
          color: RegionMapPalette.provinceLabelShadowColor,
          offset: Offset(0.5, 0.5),
        ),
      ],
    );
    for (final item in labels) {
      final platePaint = Paint()..color = item.plateColor;
      final presence = region.provinceUnitPresenceByProvinceId[item.provinceId];
      final hasCapitalIcon = item.isCapital;
      const capitalIconIds = <String>[RegionMapPalette.provinceLabelCapitalIconId];
      final presenceIconIds = resolveProvinceLabelPresenceIconIds(presence);
      final presenceIconCount = presenceIconIds.length;
      final presenceIconsWidth = presenceIconCount > 0
          ? (presenceIconCount * RegionMapPalette.provinceLabelIconRenderedPx) +
                ((presenceIconCount - 1) * RegionMapPalette.provinceLabelIconGapPx)
          : 0.0;
      final capitalInlineWidth = hasCapitalIcon
          ? RegionMapPalette.provinceLabelIconRenderedPx + RegionMapPalette.provinceLabelTextIconGapPx
          : 0.0;
      final shouldEllipsize = shouldEllipsizeProvinceLabelText(
        isCapital: item.isCapital,
      );
      final tp =
          TextPainter(
            text: TextSpan(text: item.text, style: textStyle),
            textDirection: TextDirection.ltr,
            maxLines: shouldEllipsize ? 3 : null,
            ellipsis: shouldEllipsize ? '…' : null,
          )..layout(
            maxWidth: shouldEllipsize
                ? RegionMapPalette.provinceLabelMaxWidthPx
                : double.infinity,
          );

      final tw = tp.width;
      final th = tp.height;
      final singleLinePresenceWidth = presenceIconCount > 0
          ? RegionMapPalette.provinceLabelTextIconGapPx + presenceIconsWidth
          : 0.0;
      final singleLineContentWidth =
          capitalInlineWidth + tw + singleLinePresenceWidth;
      final wrapIconsToSecondLine = shouldWrapProvinceLabelPresenceIcons(
        textWidthPx: tw,
        iconCount: presenceIconCount,
      );
      final lineOneWidth = capitalInlineWidth + tw;
      final lineOneHeight = hasCapitalIcon
          ? math.max(th, RegionMapPalette.provinceLabelIconRenderedPx)
          : th;
      final contentWidth = wrapIconsToSecondLine
          ? math.max(lineOneWidth, presenceIconsWidth)
          : singleLineContentWidth;
      final contentHeight = wrapIconsToSecondLine
          ? lineOneHeight +
                RegionMapPalette.provinceLabelTextIconGapPx +
                RegionMapPalette.provinceLabelIconRenderedPx
          : math.max(
              lineOneHeight,
              presenceIconCount > 0 ? RegionMapPalette.provinceLabelIconRenderedPx : 0,
            );
      const pad = RegionMapPalette.provinceLabelPlatePaddingPx;
      final bw = contentWidth + pad * 2;
      final bh = contentHeight + pad * 2;
      final center = item.avoidTileX != null && item.avoidTileY != null
          ? resolveSeaZoneNamePlateCenterWorld(
              centroidTileX: item.avoidTileX!,
              centroidTileY: item.avoidTileY!,
              avoidedTileX: item.avoidTileX!,
              avoidedTileY: item.avoidTileY!,
              cellSize: cellSize,
              gridWidth: region.width,
              gridHeight: region.height,
              plateWidthLogicalPx: bw,
              plateHeightLogicalPx: bh,
              cameraZoom: cameraZoom,
            )
          : Offset(item.cx, item.cy);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(invZ);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, platePaint);

      if (wrapIconsToSecondLine) {
        final lineOneLeft = -lineOneWidth / 2;
        final lineOneTop = -contentHeight / 2;
        if (hasCapitalIcon) {
          _paintProvinceLabelIconsRow(
            canvas: canvas,
            iconIds: capitalIconIds,
            left: lineOneLeft,
            top:
                lineOneTop + (lineOneHeight - RegionMapPalette.provinceLabelIconRenderedPx) / 2,
            rowWidth: RegionMapPalette.provinceLabelIconRenderedPx,
          );
        }
        tp.paint(
          canvas,
          Offset(
            lineOneLeft + capitalInlineWidth,
            lineOneTop + (lineOneHeight - th) / 2,
          ),
        );
        final iconTop =
            lineOneTop + lineOneHeight + RegionMapPalette.provinceLabelTextIconGapPx;
        _paintProvinceLabelIconsRow(
          canvas: canvas,
          iconIds: presenceIconIds,
          top: iconTop,
          rowWidth: presenceIconsWidth,
        );
      } else {
        final rowLeft = -singleLineContentWidth / 2;
        final rowTop = -contentHeight / 2;
        if (hasCapitalIcon) {
          _paintProvinceLabelIconsRow(
            canvas: canvas,
            iconIds: capitalIconIds,
            left: rowLeft,
            top: rowTop + (contentHeight - RegionMapPalette.provinceLabelIconRenderedPx) / 2,
            rowWidth: RegionMapPalette.provinceLabelIconRenderedPx,
          );
        }
        final textLeft = rowLeft + capitalInlineWidth;
        final textTop = rowTop + (contentHeight - th) / 2;
        tp.paint(canvas, Offset(textLeft, textTop));
        if (presenceIconCount > 0) {
          final iconLeft = textLeft + tw + RegionMapPalette.provinceLabelTextIconGapPx;
          _paintProvinceLabelIconsRow(
            canvas: canvas,
            iconIds: presenceIconIds,
            left: iconLeft,
            top: rowTop + (contentHeight - RegionMapPalette.provinceLabelIconRenderedPx) / 2,
            rowWidth: presenceIconsWidth,
          );
        }
      }
      canvas.restore();
    }
  }
}
