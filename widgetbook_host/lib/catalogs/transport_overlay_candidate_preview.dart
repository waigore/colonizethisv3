// Widgetbook-only preview helpers for candidate transport atlases (Refs #1819).
// Not used by the player game path or TransportOverlayTilesetCache defaults.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Candidate atlas PNGs declared only on `widgetbook_host` (never in game config).
const kTransportOverlayCandidateRoadAsset =
    'packages/widgetbook_host/assets/transport_overlay_candidates/tileset_transport_road_64.png';
const kTransportOverlayCandidateRailAsset =
    'packages/widgetbook_host/assets/transport_overlay_candidates/tileset_transport_rail_64.png';

/// Shipped atlases from the app package (comparison stories only).
const kTransportOverlayShippedRoadAsset =
    'packages/colonizethis_app/assets/images/terrain/tilesets/tileset_transport_road_64.png';
const kTransportOverlayShippedRailAsset =
    'packages/colonizethis_app/assets/images/terrain/tilesets/tileset_transport_rail_64.png';

/// Canonical 4×4 × 64px packing (matches shipped JSON sidecars).
ui.Rect transportOverlayMaskRect(int mask) {
  assert(mask >= 0 && mask <= 15);
  return ui.Rect.fromLTWH(
    (mask % 4) * 64.0,
    (mask ~/ 4) * 64.0,
    64,
    64,
  );
}

enum TransportOverlayPreviewFamily { road, rail }

String transportOverlayCandidateAsset(TransportOverlayPreviewFamily family) {
  return switch (family) {
    TransportOverlayPreviewFamily.road => kTransportOverlayCandidateRoadAsset,
    TransportOverlayPreviewFamily.rail => kTransportOverlayCandidateRailAsset,
  };
}

String transportOverlayShippedAsset(TransportOverlayPreviewFamily family) {
  return switch (family) {
    TransportOverlayPreviewFamily.road => kTransportOverlayShippedRoadAsset,
    TransportOverlayPreviewFamily.rail => kTransportOverlayShippedRailAsset,
  };
}

Future<ui.Image> loadTransportOverlayAtlasImage(String assetKey) async {
  final data = await rootBundle.load(assetKey);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// All masks `0..15` from one atlas at readable scale.
class TransportOverlayCandidateMaskGrid extends StatefulWidget {
  const TransportOverlayCandidateMaskGrid({
    super.key,
    required this.family,
    this.atlasAssetKey,
    this.tileDisplayPx = 48,
  });

  final TransportOverlayPreviewFamily family;
  final String? atlasAssetKey;
  final double tileDisplayPx;

  @override
  State<TransportOverlayCandidateMaskGrid> createState() =>
      _TransportOverlayCandidateMaskGridState();
}

class _TransportOverlayCandidateMaskGridState
    extends State<TransportOverlayCandidateMaskGrid> {
  ui.Image? _image;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TransportOverlayCandidateMaskGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.family != widget.family ||
        oldWidget.atlasAssetKey != widget.atlasAssetKey) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _image = null;
    });
    try {
      final key =
          widget.atlasAssetKey ?? transportOverlayCandidateAsset(widget.family);
      final image = await loadTransportOverlayAtlasImage(key);
      if (!mounted) return;
      setState(() => _image = image);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_error != null) {
      return Center(child: Text('Failed to load atlas: $_error'));
    }
    final image = _image;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final cell = widget.tileDisplayPx;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.family.name} — masks 0..15 (candidate)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var mask = 0; mask < 16; mask++)
                Column(
                  children: [
                    CustomPaint(
                      size: Size(cell, cell),
                      painter: _AtlasTilePainter(
                        image: image,
                        src: transportOverlayMaskRect(mask),
                      ),
                    ),
                    Text('$mask', style: theme.textTheme.labelSmall),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Straight / corner / T / cross / short path using candidate tiles.
class TransportOverlayCandidateNetworkJoins extends StatefulWidget {
  const TransportOverlayCandidateNetworkJoins({
    super.key,
    required this.family,
    this.atlasAssetKey,
    this.tileDisplayPx = 40,
  });

  final TransportOverlayPreviewFamily family;
  final String? atlasAssetKey;
  final double tileDisplayPx;

  @override
  State<TransportOverlayCandidateNetworkJoins> createState() =>
      _TransportOverlayCandidateNetworkJoinsState();
}

class _TransportOverlayCandidateNetworkJoinsState
    extends State<TransportOverlayCandidateNetworkJoins> {
  ui.Image? _image;
  Object? _error;

  // N=1 E=2 S=4 W=8
  static const _samples = <(String, List<List<int>>)>[
    ('Straight N/S', [
      [5],
      [5],
      [5],
    ]),
    ('Straight E/W', [
      [10, 10, 10],
    ]),
    ('Corner', [
      [3, 10],
      [5, 0],
    ]),
    ('T-junction', [
      [10, 7, 10],
      [0, 5, 0],
    ]),
    ('Cross', [
      [5],
      [15],
      [5],
    ]),
    ('Short path', [
      [2, 10, 10, 8],
      [0, 0, 0, 5],
      [0, 0, 0, 5],
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final key =
          widget.atlasAssetKey ?? transportOverlayCandidateAsset(widget.family);
      final image = await loadTransportOverlayAtlasImage(key);
      if (!mounted) return;
      setState(() => _image = image);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_error != null) {
      return Center(child: Text('Failed to load atlas: $_error'));
    }
    final image = _image;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final cell = widget.tileDisplayPx;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${widget.family.name} — network joins (candidate)',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final sample in _samples) ...[
          Text(sample.$1, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          _maskGrid(image, sample.$2, cell),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _maskGrid(ui.Image image, List<List<int>> rows, double cell) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mask in row)
                CustomPaint(
                  size: Size(cell, cell),
                  painter: _AtlasTilePainter(
                    image: image,
                    src: transportOverlayMaskRect(mask),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Side-by-side shipped vs candidate for one family.
class TransportOverlayCandidateCompare extends StatefulWidget {
  const TransportOverlayCandidateCompare({
    super.key,
    required this.family,
    this.tileDisplayPx = 40,
  });

  final TransportOverlayPreviewFamily family;
  final double tileDisplayPx;

  @override
  State<TransportOverlayCandidateCompare> createState() =>
      _TransportOverlayCandidateCompareState();
}

class _TransportOverlayCandidateCompareState
    extends State<TransportOverlayCandidateCompare> {
  ui.Image? _shipped;
  ui.Image? _candidate;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final shipped = await loadTransportOverlayAtlasImage(
        transportOverlayShippedAsset(widget.family),
      );
      final candidate = await loadTransportOverlayAtlasImage(
        transportOverlayCandidateAsset(widget.family),
      );
      if (!mounted) return;
      setState(() {
        _shipped = shipped;
        _candidate = candidate;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_error != null) {
      return Center(child: Text('Failed to load atlases: $_error'));
    }
    if (_shipped == null || _candidate == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${widget.family.name} — shipped vs candidate',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _column(theme, 'Shipped', _shipped!),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _column(theme, 'Candidate', _candidate!),
            ),
          ],
        ),
      ],
    );
  }

  Widget _column(ThemeData theme, String label, ui.Image image) {
    final cell = widget.tileDisplayPx;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var mask = 0; mask < 16; mask++)
              CustomPaint(
                size: Size(cell, cell),
                painter: _AtlasTilePainter(
                  image: image,
                  src: transportOverlayMaskRect(mask),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AtlasTilePainter extends CustomPainter {
  _AtlasTilePainter({required this.image, required this.src});

  final ui.Image image;
  final ui.Rect src;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _AtlasTilePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.src != src;
  }
}
