import 'package:flutter/material.dart';

/// Shared loading indicator for app overlays/dialogs.
class CtLoadingIndicator extends StatelessWidget {
  const CtLoadingIndicator({
    super.key,
    this.strokeWidth = 4,
    this.size,
    this.color,
    this.center = true,
  });

  final double strokeWidth;
  final double? size;
  final Color? color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
    );
    if (!center) {
      return indicator;
    }
    return Center(child: indicator);
  }
}
