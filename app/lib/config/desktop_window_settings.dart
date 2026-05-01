import 'dart:ui' show Rect;

import 'constants.dart';

abstract final class DesktopWindowSettingsKeys {
  static const String startupMaximized = 'desktop.startupMaximized';
  static const String lastWindowState = 'desktop.lastWindowState';
}

class DesktopWindowState {
  const DesktopWindowState({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.maximized,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final bool maximized;

  Rect toRect() => Rect.fromLTWH(x, y, width, height);

  Map<String, Object> toMap() => <String, Object>{
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'maximized': maximized,
  };

  static DesktopWindowState? fromSettingsValue(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }
    final x = _readFiniteDouble(value['x']);
    final y = _readFiniteDouble(value['y']);
    final width = _readFiniteDouble(value['width']);
    final height = _readFiniteDouble(value['height']);
    final maximized = value['maximized'];
    if (x == null || y == null || width == null || height == null) {
      return null;
    }
    if (maximized is! bool) {
      return null;
    }
    if (width < kDesktopWindowMinWidth || height < kDesktopWindowMinHeight) {
      return null;
    }
    if (!_isWithinReasonableBounds(x, y, width, height)) {
      return null;
    }
    return DesktopWindowState(
      x: x,
      y: y,
      width: width,
      height: height,
      maximized: maximized,
    );
  }

  static bool _isWithinReasonableBounds(
    double x,
    double y,
    double width,
    double height,
  ) {
    const limit = 50000.0;
    return x.abs() < limit &&
        y.abs() < limit &&
        width.abs() < limit &&
        height.abs() < limit;
  }

  static double? _readFiniteDouble(Object? value) {
    if (value is num) {
      final converted = value.toDouble();
      if (converted.isFinite) {
        return converted;
      }
    }
    return null;
  }
}
