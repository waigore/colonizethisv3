
part of 'region_map_component.dart';

extension _CtRegionMapRenderMarkers on CtRegionMapComponent {
  void _paintCivilianTileMarkers(Canvas canvas) {
    if (region.civilianTileMarkers.isEmpty) return;
    for (final marker in region.civilianTileMarkers) {
      if (marker.x < 0 ||
          marker.x >= region.width ||
          marker.y < 0 ||
          marker.y >= region.height) {
        continue;
      }
      final cell = region.cellAt(marker.x, marker.y);
      if (regionMapSkipPointMarkerOnCell(
        playerConstrainedVisibility:
            visibilityMode == CtMapVisibilityMode.playerConstrained,
        cellVisibility: _visibilityForTerrain(cell),
      )) {
        continue;
      }
      final left = marker.x * cellSize;
      final top = marker.y * cellSize;
      final selected = selectedCivilianTileKey == marker.tileKey;
      final blinkAlpha = selected
          ? _kHoveredProvinceGlowOpacityMid +
                _kHoveredProvinceGlowOpacityAmplitude *
                    math.sin(
                      _hoverAnimationT * _kHoveredProvinceGlowAngularFrequency,
                    )
          : 1.0;

      final icon = civilianIconCache.getIcon(
        unitType: marker.representativeUnitType,
        grayscale: marker.representativeIsAssigned,
      );
      if (icon != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          CivilianIconCache.iconSize,
          CivilianIconCache.iconSize,
        );
        final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
        final paint = Paint();
        final alpha = blinkAlpha.clamp(0.35, 1.0);
        if (marker.representativeIsAssigned) {
          paint.colorFilter = const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]);
        }
        paint.color = Colors.white.withValues(alpha: alpha);
        canvas.drawImageRect(icon, srcRect, dstRect, paint);
      } else {
        final fallback = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(
            0xFF495057,
          ).withValues(alpha: blinkAlpha.clamp(0.35, 1.0));
        canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), fallback);
      }

      if (marker.stackCount <= 1) continue;
      final badgeRadius = math.max(7.0, cellSize * 0.2);
      final badgeCx = left + cellSize - badgeRadius;
      final badgeCy = top + cellSize - badgeRadius;
      final badgeFill = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black.withValues(alpha: blinkAlpha.clamp(0.35, 1.0));
      canvas.drawCircle(Offset(badgeCx, badgeCy), badgeRadius, badgeFill);
      final badgeText = TextPainter(
        text: TextSpan(
          text: '${marker.stackCount}',
          style: TextStyle(
            color: Colors.white,
            fontSize: math.max(8.0, cellSize * 0.24),
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      badgeText.paint(
        canvas,
        Offset(badgeCx - badgeText.width / 2, badgeCy - badgeText.height / 2),
      );
    }
  }

  void _paintFleetTileMarkers(Canvas canvas) {
    if (region.fleetTileMarkers.isEmpty) {
      return;
    }
    for (final marker in region.fleetTileMarkers) {
      if (marker.x < 0 ||
          marker.x >= region.width ||
          marker.y < 0 ||
          marker.y >= region.height) {
        continue;
      }
      final left = marker.x * cellSize;
      final top = marker.y * cellSize;
      final icon = fleetIconCache.getIcon();
      if (icon != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          FleetIconCache.iconSize,
          FleetIconCache.iconSize,
        );
        final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
        final paint = Paint();
        if (marker.renderGrayscale) {
          paint.colorFilter = const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]);
        }
        canvas.drawImageRect(icon, srcRect, dstRect, paint);
      } else {
        final fallback = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF1c3d5a);
        canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), fallback);
      }

      if (marker.stackCount <= 1) {
        continue;
      }
      final badgeRadius = math.max(7.0, cellSize * 0.2);
      final badgeCx = left + cellSize - badgeRadius;
      final badgeCy = top + cellSize - badgeRadius;
      final badgeFill = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black;
      canvas.drawCircle(Offset(badgeCx, badgeCy), badgeRadius, badgeFill);
      final badgeText = TextPainter(
        text: TextSpan(
          text: '${marker.stackCount}',
          style: TextStyle(
            color: Colors.white,
            fontSize: math.max(8.0, cellSize * 0.24),
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      badgeText.paint(
        canvas,
        Offset(badgeCx - badgeText.width / 2, badgeCy - badgeText.height / 2),
      );
    }
  }

  void _paintValidTilesGlow(Canvas canvas) {
    final keys = validTileKeys!;
    final t = _hoverAnimationT;
    final opacity =
        _kValidWorkTargetGlowOpacityBase +
        _kValidWorkTargetGlowOpacityAmplitude *
            (_kSinNormalizedMid +
                _kSinNormalizedMid *
                    math.sin(t * _kValidWorkTargetGlowTimeScale));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kMapValidTileTargetStrokeWidth
      ..color = _kValidWorkTargetStrokeYellow.withValues(alpha: opacity);
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        final tileKey = '${region.regionId}|${cell.regionCellId}|$x|$y';
        if (!keys.contains(tileKey)) continue;
        final left = x * cellSize;
        final top = y * cellSize;
        canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      }
    }
  }

  void _paintSelectedTile(Canvas canvas) {
    _paintTileOutlineRing(
      canvas,
      tileKey: selectedTileKey!,
      color: _kMapSelectedHighlightOrange,
      strokeWidth: kMapSelectedTileStrokeWidth,
    );
  }

  void _paintSecondaryHighlightTile(Canvas canvas) {
    _paintTileOutlineRing(
      canvas,
      tileKey: secondaryHighlightTileKey!,
      color: _kMapSecondarySelectionCyan,
      strokeWidth: kMapSecondaryHighlightStrokeWidth,
    );
  }

  void _paintTileOutlineRing(
    Canvas canvas, {
    required String tileKey,
    required Color color,
    required double strokeWidth,
  }) {
    final parsed = tryParseTileKey(tileKey);
    if (parsed == null || parsed.regionId != region.regionId) return;
    final x = parsed.x;
    final y = parsed.y;
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return;
    final left = x * cellSize;
    final top = y * cellSize;
    final rect = Rect.fromLTWH(left, top, cellSize, cellSize);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    canvas.drawRect(rect, paint);
  }

  void _paintSelector(Canvas canvas) {
    final x = _hoveredTileX!;
    final y = _hoveredTileY!;
    final bounce =
        _kHoverSelectorBounceBaseline +
        _kHoverSelectorBounceAmplitude *
            math.sin(_hoverAnimationT * _kHoveredProvinceGlowAngularFrequency);
    final cx = x * cellSize + cellSize / 2;
    final cy = y * cellSize + cellSize / 2;
    final half = (cellSize / 2 - 2.0) * bounce;
    final left = cx - half;
    final top = cy - half;
    final size = half * 2;
    final rect = Rect.fromLTWH(left, top, size, size);
    final color = (validTileKeys != null && validTileKeys!.isNotEmpty)
        ? _kMapSelectedHighlightOrange
        : _kMapHoverSelectorIdle;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kMapHoverSelectorStrokeWidth
      ..color = color;
    canvas.drawRect(rect, paint);
  }
}
