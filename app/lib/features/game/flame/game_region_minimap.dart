import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_assets.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../providers/region_minimap_provider.dart';
import 'region_map_viewport_snapshot.dart'
    show
        RegionMapViewportSnapshot,
        kRegionMapZoomMultiplierMax,
        kRegionMapZoomMultiplierMin;
import '../../../widgets/ct_slider.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'game_screen_shared.dart';
import 'region_minimap_math.dart';

/// Terrain base colors for the region minimap (flat fills). SPEC/ui/empire-overview.md § Region minimap.
const Map<TerrainType, Color> kRegionMinimapTerrainColors = {
  TerrainType.plains: Color(0xFFA5D6A7),
  TerrainType.hardwoodForest: Color(0xFF2E7D32),
  TerrainType.scrubForest: Color(0xFF7CB342),
  TerrainType.hills: Color(0xFFB0BEC5),
  TerrainType.mountain: Color(0xFF546E7A),
  TerrainType.swamp: Color(0xFF6D4C41),
  TerrainType.desert: Color(0xFFD7CCC8),
};

/// Deep sea fill when [CellViewData.isSea] is true.
const Color kRegionMinimapSeaColor = Color(0xFF0D47A1);

/// Opacity for fogged tiles (terrain still visible underneath per SPEC).
const double kRegionMinimapFoggedAlpha = 0.55;

/// Dismissible region minimap (Empire overview). SPEC/ui/empire-overview.md § Region minimap.
///
/// [cellSizePx] must match [RegionMapViewData.cellSize] used by the Flame-backed region map for this
/// region so world↔minimap math matches [RegionMapViewportSnapshot] (see SPEC/ui/map-widget.md).
///
/// Narrow layout (issue #2870 S3, `MediaQuery.size.width < kNarrowBreakpoint`):
/// the host constructs this widget with `narrow: true`. The minimap grid then
/// fits the active region's aspect ratio into a 90 × 70 dp box per
/// `SPEC/ui/mobile-adaptation.md` § In-game shell and the
/// `.minimap-panel @media (max-width:600px)` rule in
/// `SPEC/ui/mockups/GAME10001-game-screen.html`. Wide chrome (corner-control
/// brackets, panel padding, toggle button, zoom slider) is unchanged.
class GameRegionMinimap extends ConsumerWidget {
  const GameRegionMinimap({
    required this.region,
    required this.viewportSnapshot,
    required this.bus,
    this.cellSizePx = 24,
    this.narrow = false,
    super.key,
  });

  final RegionMapViewData region;
  final RegionMapViewportSnapshot? viewportSnapshot;
  final AppEventBus bus;
  final double cellSizePx;

  /// When true, fit the grid into the narrow 90 × 70 dp box per
  /// `SPEC/ui/mobile-adaptation.md` § In-game shell (issue #2870 S3).
  /// When false (default), preserve the wide-layout behavior of capping
  /// the longer aspect side at [defaultMaxExtent].
  final bool narrow;

  /// Long-side cap in dp for the minimap grid under the wide / desktop
  /// layout. Preserves the pre-#2870 baseline so default-layout
  /// regression tests keep their existing dimensions.
  @visibleForTesting
  static const double defaultMaxExtent = 132;

  /// Width cap in dp for the minimap grid under narrow chrome. Mirrors
  /// the canonical measurement in `SPEC/ui/mobile-adaptation.md` §
  /// In-game shell ("90 × 70 dp") and the mockup
  /// `.minimap-panel @media (max-width:600px)` rule.
  @visibleForTesting
  static const double narrowMaxWidth = 90;

  /// Height cap in dp for the minimap grid under narrow chrome. Mirrors
  /// the canonical measurement in `SPEC/ui/mobile-adaptation.md` §
  /// In-game shell ("90 × 70 dp") and the mockup
  /// `.minimap-panel @media (max-width:600px)` rule.
  @visibleForTesting
  static const double narrowMaxHeight = 70;

  /// Computes the inner [CustomPaint] grid size for a region of the given
  /// `aspect` ratio (`region.width / region.height`) under the wide or
  /// narrow chrome. Visible for testing so the SPEC's 90 × 70 dp bounding
  /// box and the wide regression baseline can be pinned without pumping
  /// the full widget tree.
  @visibleForTesting
  static Size computeMapSize({required double aspect, required bool narrow}) {
    if (narrow) {
      final boxAspect = narrowMaxWidth / narrowMaxHeight;
      if (aspect >= boxAspect) {
        return Size(narrowMaxWidth, narrowMaxWidth / aspect);
      }
      return Size(narrowMaxHeight * aspect, narrowMaxHeight);
    }
    if (aspect >= 1) {
      return Size(defaultMaxExtent, defaultMaxExtent / aspect);
    }
    return Size(defaultMaxExtent * aspect, defaultMaxExtent);
  }

  /// Internal padding between the dark editorial-monocle minimap panel border
  /// and the [CustomPaint] grid. Matches mockup `.minimap-panel { padding:2px }`
  /// (`SPEC/ui/mockups/GAME10001-game-screen.html`). Unchanged at narrow —
  /// the panel padding is part of the chrome, not the grid box.
  static const double panelPadding = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(regionMinimapVisibleProvider);
    final viewport = viewportSnapshot?.regionId == region.regionId
        ? viewportSnapshot
        : null;
    final aspect = region.width / region.height;
    final mapSize = computeMapSize(aspect: aspect, narrow: narrow);

    final zoomMultiplier = viewport == null
        ? 1.0
        : viewport.zoomMultiplier.clamp(
            kRegionMapZoomMultiplierMin,
            kRegionMapZoomMultiplierMax,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (visible) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: EditorialMonoclePalette.bgDeep,
              border: Border.all(
                color: EditorialMonoclePalette.border,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(panelPadding),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerMove: (event) {
                  if (!event.down || event.delta == Offset.zero) {
                    return;
                  }
                  _onPan(delta: event.delta, mapSize: mapSize);
                },
                child: GestureDetector(
                  key: kRegionMinimapGestureKey,
                  behavior: HitTestBehavior.opaque,
                  // Tap-up avoids a center event at pointer-down (which interfered with drags).
                  onTapUp: (d) =>
                      _onTap(local: d.localPosition, mapSize: mapSize),
                  child: SizedBox(
                    width: mapSize.width,
                    height: mapSize.height,
                    child: CustomPaint(
                      key: kRegionMinimapCustomPaintKey,
                      painter: _RegionMinimapPainter(
                        region: region,
                        cellSizePx: cellSizePx,
                        viewport: viewport?.regionId == region.regionId
                            ? viewport
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        _MinimapZoomControls(
          regionId: region.regionId,
          bus: bus,
          viewportMultiplier: zoomMultiplier,
          trackWidth: mapSize.width,
          theme: Theme.of(context),
          trailing: _MinimapToggleButton(
            visible: visible,
            onTap: () =>
                ref.read(regionMinimapVisibleProvider.notifier).toggle(),
          ),
        ),
      ],
    );
  }

  void _onTap({required Offset local, required Size mapSize}) {
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final world = minimapLocalToWorldCenter(
      localOnMinimap: local,
      minimapSize: mapSize,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    bus.emit(
      RequestRegionMapCameraCenterWorldEvent(
        regionId: region.regionId,
        worldCenterX: world.dx,
        worldCenterY: world.dy,
      ),
    );
  }

  void _onPan({required Offset delta, required Size mapSize}) {
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final w = minimapDeltaToWorldDelta(
      minimapDelta: delta,
      minimapSize: mapSize,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    bus.emit(
      RequestRegionMapCameraPanWorldDeltaEvent(
        regionId: region.regionId,
        worldDx: w.dx,
        worldDy: w.dy,
      ),
    );
  }
}

/// Minimap zoom label + [CtSlider] (non-Material), with local value during drag so
/// the thumb and % label track the gesture before the viewport snapshot catches up.
class _MinimapZoomControls extends StatefulWidget {
  const _MinimapZoomControls({
    required this.regionId,
    required this.bus,
    required this.viewportMultiplier,
    required this.trackWidth,
    required this.theme,
    required this.trailing,
  });

  final String regionId;
  final AppEventBus bus;
  final double viewportMultiplier;
  final double trackWidth;
  final ThemeData theme;
  final Widget trailing;

  @override
  State<_MinimapZoomControls> createState() => _MinimapZoomControlsState();
}

class _MinimapZoomControlsState extends State<_MinimapZoomControls> {
  double? _dragMultiplier;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant _MinimapZoomControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.regionId != widget.regionId) {
      _dragMultiplier = null;
      _dragging = false;
    }
  }

  double get _displayMultiplier {
    final v = _dragMultiplier ?? widget.viewportMultiplier;
    return v.clamp(kRegionMapZoomMultiplierMin, kRegionMapZoomMultiplierMax);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final pct = (_displayMultiplier * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: widget.trackWidth,
          child: Text(
            l10n.common_percent(pct),
            textAlign: TextAlign.center,
            style: widget.theme.textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: widget.trackWidth,
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  label: l10n.regionMinimap_mapZoom,
                  value: l10n.regionMinimap_zoomSemanticsValue(pct),
                  slider: true,
                  child: Tooltip(
                    message: l10n.regionMinimap_mapZoom,
                    child: Center(
                      child: CtSlider(
                        key: kRegionMinimapZoomSliderKey,
                        value: _displayMultiplier,
                        min: kRegionMapZoomMultiplierMin,
                        max: kRegionMapZoomMultiplierMax,
                        divisions: 0,
                        onDragStart: () {
                          setState(() => _dragging = true);
                        },
                        onChanged: (v) {
                          widget.bus.emit(
                            RequestRegionMapSetZoomMultiplierEvent(
                              regionId: widget.regionId,
                              zoomMultiplier: v,
                            ),
                          );
                          if (_dragging) {
                            setState(() => _dragMultiplier = v);
                          }
                        },
                        onDragEnd: () {
                          setState(() {
                            _dragging = false;
                            _dragMultiplier = null;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              widget.trailing,
            ],
          ),
        ),
      ],
    );
  }
}

/// Dark editorial-monocle 32 × 32 dp show/hide toggle for the region minimap.
///
/// Mirrors mockup `.minimap-toggle`
/// (`SPEC/ui/mockups/GAME10001-game-screen.html`) and the
/// [GameMapCornerControls](game_map_corner_controls.dart) chrome family
/// per `SPEC/ui/empire-overview.md` § Region minimap chrome
/// (dark editorial-monocle): a flat `--bg-deep` surface with a 1 px
/// `--border` outline, centered glyph tinted via `ColorFiltered(srcIn)`
/// to `--accent-dim` (default) → `--accent-bright` (hover / pressed),
/// outline shifting to `--accent-dim` on the same hover / pressed
/// transition over `120 ms` (`Curves.easeOut`).
class _MinimapToggleButton extends StatefulWidget {
  const _MinimapToggleButton({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  /// Side length of the toggle tap target. Matches the corner-controls
  /// 32 dp tap target convention referenced by SPEC `Region minimap`:
  /// "same padding/hit target pattern as corner controls".
  static const double buttonSize = 32;

  /// Side length of the centered glyph. Preserves the existing 20 dp
  /// minimap icon so the visible silhouette inside the dark surface is
  /// unchanged from the legacy white-Material chrome.
  static const double iconSize = 20;

  /// Hover/press transition duration. Matches
  /// [GameMapCornerControls](game_map_corner_controls.dart) so the row
  /// of map chrome reads as one editorial-monocle family.
  static const Duration animationDuration = Duration(milliseconds: 120);
  static const Curve animationCurve = Curves.easeOut;

  @override
  State<_MinimapToggleButton> createState() => _MinimapToggleButtonState();
}

class _MinimapToggleButtonState extends State<_MinimapToggleButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  Color get _borderColor => (_hovered || _pressed)
      ? EditorialMonoclePalette.accentDim
      : EditorialMonoclePalette.border;

  Color get _iconColor => (_hovered || _pressed)
      ? EditorialMonoclePalette.accentBright
      : EditorialMonoclePalette.accentDim;

  @override
  Widget build(BuildContext context) {
    final tooltip = widget.visible
        ? 'Hide region minimap'
        : 'Show region minimap';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: SizedBox(
            key: kRegionMinimapToggleKey,
            width: _MinimapToggleButton.buttonSize,
            height: _MinimapToggleButton.buttonSize,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: _setPressed,
                child: AnimatedContainer(
                  duration: _MinimapToggleButton.animationDuration,
                  curve: _MinimapToggleButton.animationCurve,
                  decoration: BoxDecoration(
                    color: EditorialMonoclePalette.bgDeep,
                    border: Border.all(color: _borderColor, width: 1),
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        _iconColor,
                        BlendMode.srcIn,
                      ),
                      child: StrictAssetIcon(
                        assetPath:
                            '${kAppIconAssetPrefix}ui_icon_region_minimap.png',
                        width: _MinimapToggleButton.iconSize,
                        height: _MinimapToggleButton.iconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionMinimapPainter extends CustomPainter {
  _RegionMinimapPainter({
    required this.region,
    required this.cellSizePx,
    required this.viewport,
  });

  final RegionMapViewData region;
  final double cellSizePx;
  final RegionMapViewportSnapshot? viewport;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / region.width;
    final cellH = size.height / region.height;
    final paint = Paint();

    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
        if (cell.visibility == TileVisibility.unrevealed) {
          paint.color = Colors.black;
          canvas.drawRect(rect, paint);
          continue;
        }
        final base = cell.isSea
            ? kRegionMinimapSeaColor
            : kRegionMinimapTerrainColors[cell.terrainType ??
                  TerrainType.plains]!;
        if (cell.visibility == TileVisibility.fogged) {
          paint.color = base.withValues(alpha: kRegionMinimapFoggedAlpha);
        } else {
          paint.color = base;
        }
        canvas.drawRect(rect, paint);
      }
    }

    final v = viewport;
    if (v == null) return;
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final indicator = minimapViewportIndicatorRect(
      viewport: v,
      minimapSize: size,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(indicator, border);
  }

  @override
  bool shouldRepaint(covariant _RegionMinimapPainter oldDelegate) {
    return oldDelegate.region != region ||
        oldDelegate.cellSizePx != cellSizePx ||
        oldDelegate.viewport != viewport;
  }
}
