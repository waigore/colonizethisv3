// Responsive chrome, header, and shared body text styles for the province overlay.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'province_sea_zone_detail_overlay.dart';

extension _ProvinceSeaZoneDetailOverlayChrome on ProvinceSeaZoneDetailOverlay {
  Widget buildResponsivePanel(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
    _OverlayContent content,
  ) {
    final maxHeight = _resolveMaxHeight(context, constraints, isNarrow);
    return Padding(
      padding: const EdgeInsets.all(CtSpacing.m),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: CtPanel(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: isNarrow ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverlayHeader(context),
              Flexible(child: _buildOverlayBody(isNarrow, content)),
            ],
          ),
        ),
      ),
    );
  }

  double _resolveMaxHeight(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
  ) {
    // Narrow full-width (mobile): cap at one-third screen (SPEC). Narrow
    // side rail (width < screen): use parent height. Parent already capped
    // to ≤ one-third (bottom slot): honor that height.
    final mqSize = MediaQuery.sizeOf(context);
    final thirdScreen = mqSize.height * 0.33;
    final isFullWidthNarrow =
        isNarrow && (constraints.maxWidth >= mqSize.width - 8);
    if (!isNarrow) {
      return constraints.maxHeight;
    }
    if (!constraints.maxHeight.isFinite) {
      return thirdScreen;
    }
    if (constraints.maxHeight <= thirdScreen + 1) {
      return constraints.maxHeight;
    }
    if (isFullWidthNarrow) {
      return thirdScreen;
    }
    return constraints.maxHeight;
  }

  Widget _buildOverlayHeader(BuildContext context) {
    final l10n = appL10n(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: CtSpacing.ml,
        right: CtSpacing.m,
        top: CtSpacing.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isSeaZone(displayId)
                  ? l10n.provinceOverlay_titleSeaZone
                  : l10n.provinceOverlay_titleProvince,
              style: _overlayTitleStyle(context),
            ),
          ),
          _OverlayCloseButton(onClose: onClose),
        ],
      ),
    );
  }

  Widget _buildOverlayBody(bool isNarrow, _OverlayContent content) {
    if (isNarrow) {
      return CtTabStrip(
        tabLabels: content.tabLabels,
        tabViews: content.tabViews
            .map(
              (w) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: w,
              ),
            )
            .toList(),
        contentPadding: const EdgeInsets.all(CtSpacing.ml),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.ml),
      child: content.sections,
    );
  }
}

/// Shared `TextStyle` for every obfuscated `???` body cell in the overlay.
/// Renders fully-unrevealed province/sea-zone sections, partially-revealed
/// Tile rows (`Coordinates: ???`, `Terrain: ???`, …), and the intel-gated
/// Economic / Military / Civilian / Naval body fallbacks in the canonical
/// hidden-information muted token so the dark editorial-monocle theme owns
/// the obfuscation surface. See
/// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme obfuscated `???`
/// body tokens. `EditorialMonoclePalette.muted` is a runtime OKLCH → Color
/// getter so this style cannot be `const`.
TextStyle _obfuscatedBodyStyle() =>
    TextStyle(color: EditorialMonoclePalette.muted);

/// Convenience widget for an obfuscated body `Text(...)` row painted in the
/// shared muted token. Centralises every `Text(l10n.provinceOverlay_unknown)`
/// / `Text(l10n.provinceOverlay_tile*Unknown)` call so a future change to the
/// obfuscation token only updates `_obfuscatedBodyStyle` (and the SPEC).
Widget _obfuscatedBodyText(String data) =>
    Text(data, style: _obfuscatedBodyStyle());

/// Shared `TextStyle` for every live-data body row in the overlay that
/// renders exact world-state values (Political "Name" / "Owner", Tile
/// section coordinates / terrain / civilian-units, sea-zone "Sea zone"
/// display name). Centralises the canonical `EditorialMonoclePalette.fg`
/// foreground token so a future change to the live-data token only updates
/// `_fgBodyStyle` (and the SPEC). See
/// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme Political /
/// Tile / sea-zone Political body tokens. `EditorialMonoclePalette.fg` is
/// a runtime OKLCH → Color getter so this style cannot be `const`.
TextStyle _fgBodyStyle() => TextStyle(color: EditorialMonoclePalette.fg);

/// Pixel-art overlay title text style (non-Material) under the dark
/// editorial-monocle theme. Mirrors `CtTopBar` title typography: display
/// font from `theme.textTheme.titleMedium`, `--accent` colour from
/// [EditorialMonoclePalette], and `letterSpacing: 0.05`.
/// See SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme chrome.
TextStyle _overlayTitleStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final TextStyle base =
      theme.textTheme.titleMedium ??
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  return base.copyWith(
    color: EditorialMonoclePalette.accent,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.05,
  );
}
