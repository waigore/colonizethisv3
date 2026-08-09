import 'package:flutter/material.dart';

Offset resolveSeaZoneNamePlateCenterWorld({
  required int centroidTileX,
  required int centroidTileY,
  required double cellSize,
  required int gridWidth,
  required int gridHeight,
  required double plateWidthLogicalPx,
  required double plateHeightLogicalPx,
  required double cameraZoom,
  int? avoidedTileX,
  int? avoidedTileY,
}) {
  final avoidTileX = avoidedTileX ?? centroidTileX;
  final avoidTileY = avoidedTileY ?? centroidTileY;
  final invZ = 1.0 / cameraZoom.clamp(0.25, 4.0);
  final ww = plateWidthLogicalPx * invZ / 2;
  final hh = plateHeightLogicalPx * invZ / 2;
  final mapW = gridWidth * cellSize;
  final mapH = gridHeight * cellSize;
  final cellL = avoidTileX * cellSize;
  final cellT = avoidTileY * cellSize;
  final cellR = cellL + cellSize;
  final cellB = cellT + cellSize;
  const gap = 1.0;
  var cx = (centroidTileX + 0.5) * cellSize;
  bool overlapsCell(double pcx, double pcy) {
    final l = pcx - ww;
    final r = pcx + ww;
    final t = pcy - hh;
    final b = pcy + hh;
    return !(r <= cellL || l >= cellR || b <= cellT || t >= cellB);
  }
  ({double x, double y}) clampPlateCenter(double pcx, double pcy) {
    var x = pcx;
    var y = pcy;
    var l = x - ww;
    var r = x + ww;
    if (l < 0) x -= l;
    r = x + ww;
    if (r > mapW) x -= r - mapW;
    l = x - ww;
    if (l < 0) x = ww;
    var t = y - hh;
    var b = y + hh;
    if (t < 0) y -= t;
    b = y + hh;
    if (b > mapH) y -= b - mapH;
    t = y - hh;
    if (t < 0) y = hh;
    return (x: x, y: y);
  }
  final aboveY = cellT - gap - hh;
  final aboveTop = aboveY - hh;
  final useAbove = aboveTop >= 0;
  var cy = useAbove ? aboveY : cellB + gap + hh;
  var clamped = clampPlateCenter(cx, cy);
  cx = clamped.x;
  cy = clamped.y;
  if (overlapsCell(cx, cy)) {
    if (useAbove) {
      cy = cellB + gap + hh;
    } else if (aboveTop >= 0) {
      cy = aboveY;
    }
    clamped = clampPlateCenter(cx, cy);
    cx = clamped.x;
    cy = clamped.y;
  }
  for (var i = 0; i < 48 && overlapsCell(cx, cy); i++) {
    final midY = (cellT + cellB) / 2;
    if (cy < midY) {
      cy -= 1;
    } else {
      cy += 1;
    }
    clamped = clampPlateCenter(cx, cy);
    cx = clamped.x;
    cy = clamped.y;
  }
  return Offset(cx, cy);
}
