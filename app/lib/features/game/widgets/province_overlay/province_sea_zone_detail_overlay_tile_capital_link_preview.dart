/// Localized copy for MAP20001 Tile capital-link and E-of-F rows (Refs #4149).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ProvinceTileCapitalLinkPreview;

export 'package:colonizethis_logic/colonizethis_logic.dart'
    show ProvinceTileCapitalLinkPreview;

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
