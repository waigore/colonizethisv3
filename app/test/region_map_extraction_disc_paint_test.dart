import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        extractionIndicatorRectsForIconRect,
        paintResourceExtractionDiscIndicators;

void main() {
  suppressLogsForTests();

  group('Region map extraction disc paint (#1847)', () {
    testWidgets(
      'paintResourceExtractionDiscIndicators fills effective with gold '
      'and blocked with brown with dark stroke rims (Refs #4151 Phase 3)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          const iconRect = Rect.fromLTWH(4, 4, 32, 32);
          final rects = extractionIndicatorRectsForIconRect(
            iconRect: iconRect,
            units: 2,
          );
          expect(rects, hasLength(2));
          paintResourceExtractionDiscIndicators(
            canvas: canvas,
            indicatorRects: rects,
            effectiveCount: 1,
            fogCompatibleOverlayPaint: Paint(),
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(120, 64);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(bytes, isNotNull);
          int offset(int x, int y) => (y * image.width + x) * 4;
          final c0x = rects[0].center.dx.round();
          final c0y = rects[0].center.dy.round();
          final c1x = rects[1].center.dx.round();
          final c1y = rects[1].center.dy.round();
          expect(bytes!.getUint8(offset(c0x, c0y) + 3), greaterThan(200));
          expect(bytes.getUint8(offset(c1x, c1y) + 3), greaterThan(200));
          final r0 = bytes.getUint8(offset(c0x, c0y));
          final g0 = bytes.getUint8(offset(c0x, c0y) + 1);
          final b0 = bytes.getUint8(offset(c0x, c0y) + 2);
          final r1 = bytes.getUint8(offset(c1x, c1y));
          final g1 = bytes.getUint8(offset(c1x, c1y) + 1);
          final b1 = bytes.getUint8(offset(c1x, c1y) + 2);
          expect(r0, greaterThan(230));
          expect(g0, greaterThan(180));
          expect(b0, lessThan(80));
          expect(r1, lessThan(180));
          expect((r0 - r1).abs(), greaterThan(40));
          expect((g0 - g1).abs() + (b0 - b1).abs(), greaterThan(30));

          final radius = rects[0].shortestSide * 0.5;
          final rimX = (c0x + radius - 1).round();
          final rimR = bytes.getUint8(offset(rimX, c0y));
          final rimG = bytes.getUint8(offset(rimX, c0y) + 1);
          final rimB = bytes.getUint8(offset(rimX, c0y) + 2);
          int luminance(int r, int g, int b) =>
              (r * 299 + g * 587 + b * 114) ~/ 1000;
          expect(
            luminance(rimR, rimG, rimB),
            lessThan(luminance(r0, g0, b0) - 40),
          );
        });
        await tester.pump();
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'paintResourceExtractionDiscIndicators applies fog filter to stroke '
      '(Refs #4151 Phase 3)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          const iconRect = Rect.fromLTWH(4, 4, 32, 32);
          final rects = extractionIndicatorRectsForIconRect(
            iconRect: iconRect,
            units: 1,
          );
          final fogPaint = Paint()
            ..colorFilter = const ColorFilter.mode(
              Color.fromRGBO(128, 128, 128, 0.6),
              BlendMode.modulate,
            );
          paintResourceExtractionDiscIndicators(
            canvas: canvas,
            indicatorRects: rects,
            effectiveCount: 1,
            fogCompatibleOverlayPaint: fogPaint,
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(64, 64);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(bytes, isNotNull);
          int offset(int x, int y) => (y * image.width + x) * 4;
          final cx = rects[0].center.dx.round();
          final cy = rects[0].center.dy.round();
          expect(bytes!.getUint8(offset(cx, cy)), lessThan(230));
        });
        await tester.pump();
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
