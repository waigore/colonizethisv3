/// Tile-level capital-link and extraction preview for MAP20001 (Refs #4149).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

/// Cached display data for the Tile section capital-link and E-of-F rows.
class ProvinceTileCapitalLinkPreview {
  const ProvinceTileCapitalLinkPreview({
    required this.isCapitalConnected,
    this.pathTransportLevel,
    this.extractionEffective,
    required this.extractionFull,
  });

  final bool isCapitalConnected;
  final int? pathTransportLevel;
  final int? extractionEffective;
  final int extractionFull;

  bool get showExtraction => extractionFull > 0;
}

String tileCapitalLinkLine(
  AppLocalizations l10n,
  ProvinceTileCapitalLinkPreview preview,
) {
  if (preview.isCapitalConnected) {
    final transport = preview.pathTransportLevel;
    if (transport != null) {
      return l10n.provinceOverlay_tileCapitalLinkConnectedWithTransport(
        transport,
      );
    }
    return l10n.provinceOverlay_tileCapitalLinkConnected;
  }
  return l10n.provinceOverlay_tileCapitalLinkNotConnected;
}

String? tileExtractionFromTileLine(
  AppLocalizations l10n,
  ProvinceTileCapitalLinkPreview preview,
) {
  if (!preview.showExtraction) {
    return null;
  }
  return l10n.provinceOverlay_tileExtractionFromTile(
    preview.extractionEffective ?? 0,
    preview.extractionFull,
  );
}
