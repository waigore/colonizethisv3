import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// PNG icon from the app asset bundle. Throws [FlutterError] if the asset is missing or invalid.
class StrictAssetIcon extends StatelessWidget {
  const StrictAssetIcon({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit,
  });

  /// Full asset path, e.g. `assets/icons/ui_icon_production.png`.
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Failed to load icon asset'),
          ErrorDescription(assetPath),
          DiagnosticsProperty<Object>('Error', error),
          DiagnosticsProperty<StackTrace?>(
            'Stack trace',
            stackTrace,
            showName: false,
          ),
        ]);
      },
    );
  }
}
