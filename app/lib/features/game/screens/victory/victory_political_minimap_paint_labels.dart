import 'dart:math' as math;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'victory_political_minimap_annotations.dart';

const double kVictoryMinimapSmallProvinceCellThreshold = 4;
const double kVictoryMinimapLabelFontSize = 9;
const double kVictoryMinimapSmallLabelFontSize = 7;

mixin VictoryPoliticalMinimapPaintLabels on CustomPainter {
  RegionMapViewData get region;

  void paintProvinceLabels(Canvas canvas, double cellW, double cellH) {
    final labels = computeVictoryMinimapProvinceLabels(region);
    for (final label in labels) {
      final isSmall =
          label.cellCount < kVictoryMinimapSmallProvinceCellThreshold;
      final fontSize = isSmall
          ? kVictoryMinimapSmallLabelFontSize
          : kVictoryMinimapLabelFontSize;
      final maxWidth = label.cellCount * math.min(cellW, cellH) * 0.95;
      final text = isSmall
          ? ellipsizeLabel(label.text, maxWidth, fontSize)
          : label.text;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: EditorialMonoclePalette.fg,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            shadows: const [
              Shadow(
                blurRadius: 2,
                color: Color(0xCC000000),
                offset: Offset(0.5, 0.5),
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      final offset = Offset(
        label.cx * cellW - painter.width / 2,
        label.cy * cellH - painter.height / 2,
      );
      painter.paint(canvas, offset);
    }
  }

  String ellipsizeLabel(String text, double maxWidth, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    return painter.text?.toPlainText() ?? text;
  }
}
