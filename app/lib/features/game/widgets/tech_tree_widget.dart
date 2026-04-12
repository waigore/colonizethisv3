// Tech tree graph widget. SPEC/ui/tech-tree-widget.md.

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'tech_effect_summary_lookup.dart';

/// Node position for layout. Exposed for tests (column rule: A→B→C and A→C ⇒ gap between A and C).
class TechNodePosition {
  const TechNodePosition({
    required this.techId,
    required this.x,
    required this.y,
    required this.layer,
  });
  final String techId;
  final double x;
  final double y;
  final int layer;
}

/// Category color map. SPEC/ui/tech-tree-widget.md: color-coded by category.
const Map<String, Color> _categoryColors = {
  'gathering': Color(0xFF2E7D32),
  'transport': Color(0xFF1565C0),
  'labour': Color(0xFFF9A825),
  'civilian': Color(0xFF6A1B9A),
  'diplomacy': Color(0xFF00838F),
  'naval': Color(0xFF0D47A1),
  'military': Color(0xFFC62828),
  'new-world': Color(0xFF4E342E),
};

/// Category icon map. SPEC/ui/tech-tree-widget.md: one icon per category.
const Map<String, String> _categoryIcons = {
  'gathering': '${kAppIconAssetPrefix}ui_icon_tech_gathering.png',
  'new-world': '${kAppIconAssetPrefix}ui_icon_tech_new_world.png',
  'transport': '${kAppIconAssetPrefix}ui_icon_tech_transport.png',
  'labour': '${kAppIconAssetPrefix}ui_icon_tech_labour.png',
  'civilian': '${kAppIconAssetPrefix}ui_icon_tech_civilian.png',
  'diplomacy': '${kAppIconAssetPrefix}ui_icon_tech_diplomacy.png',
  'naval': '${kAppIconAssetPrefix}ui_icon_tech_naval.png',
  'military': '${kAppIconAssetPrefix}ui_icon_tech_military.png',
};

const double _nodeWidth = 100;
const double _nodeHeight = 44;
const double _layerGap = 140;
const double _rowGap = 52;
const double _edgeStrokeWidth = 2;

/// Offset from source right edge for the vertical segment so it stays in the inter-column gap (never through nodes).
const double _edgeBendOffset = (_layerGap - _nodeWidth) / 2;

/// Full-screen tech tree graph. Left-to-right layout, explicit edges, scrollable.
/// SPEC/ui/tech-tree-widget.md.
class TechTreeWidget extends StatelessWidget {
  const TechTreeWidget({super.key, required this.game, required this.player});

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final positions = TechTreeWidget.computeLayout(techCatalog);
    if (positions.isEmpty) {
      return Center(child: Text(l10n.techTree_noTechsInCatalog));
    }
    final width = positions.map((p) => p.x).reduce(math.max) + _nodeWidth + 48;
    final height =
        positions.map((p) => p.y).reduce(math.max) + _nodeHeight + 48;
    final unlocked = player.techUnlocked ?? {};
    final inProgress = player.researchProgressByTechId?.keys.toSet() ?? {};
    final researchable = researchableTechIds(
      unlocked,
      hasDiscoveredResource: (r) =>
          hasRevealedResourceForPlayer(game, player.id, r),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _TechTreeLegend(l10n: l10n),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(width, height),
                      painter: _TechTreeEdgePainter(positions: positions),
                    ),
                    ...positions.map((pos) {
                      final tech = techById(pos.techId);
                      if (tech == null) return const SizedBox.shrink();
                      final state = _TechNodeState(
                        researched: unlocked[pos.techId] == true,
                        inProgress: inProgress.contains(pos.techId),
                        available: researchable.contains(pos.techId),
                      );
                      return Positioned(
                        left: pos.x,
                        top: pos.y,
                        width: _nodeWidth,
                        height: _nodeHeight,
                        child: _TechNode(
                          tech: tech,
                          state: state,
                          onTap: () => _showTechDialog(context, tech),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Computes topological layout: each tech in a column strictly right of all its prerequisites.
  /// For edges that span multiple columns, reserves a row slot in each intermediate column for the
  /// connector (so the horizontal segment does not pass through nodes); other techs are shifted down.
  /// Used by the widget and by tests (column rule: A→B→C and A→C ⇒ B occupies column between A and C).
  static List<TechNodePosition> computeLayout(
    Map<String, TechDefinition> catalog,
  ) {
    if (catalog.isEmpty) return [];

    // Layer: 0 = roots, 1 = one step from root, etc.
    final layerByTech = <String, int>{};
    int maxLayer = 0;
    void assignLayer(String techId) {
      if (layerByTech.containsKey(techId)) return;
      final tech = catalog[techId];
      if (tech == null) return;
      if (tech.prerequisiteIds.isEmpty) {
        layerByTech[techId] = 0;
        return;
      }
      for (final p in tech.prerequisiteIds) {
        assignLayer(p);
      }
      final prereqLayers = tech.prerequisiteIds
          .map((p) => layerByTech[p]!)
          .toList();
      final layer = 1 + (prereqLayers.reduce(math.max));
      layerByTech[techId] = layer;
      if (layer > maxLayer) maxLayer = layer;
    }

    for (final id in catalog.keys) {
      assignLayer(id);
    }

    // Group by layer, sort within layer for stable layout.
    final byLayer = <int, List<String>>{};
    for (final e in layerByTech.entries) {
      byLayer.putIfAbsent(e.value, () => []).add(e.key);
    }
    for (final list in byLayer.values) {
      list.sort((a, b) => a.compareTo(b));
    }

    // Place layers from right to left so we know target rows when reserving connector slots.
    final positionsByLayer = <int, List<TechNodePosition>>{};
    for (var layer = maxLayer; layer >= 0; layer--) {
      final ids = byLayer[layer] ?? [];
      final x = 24.0 + layer * _layerGap;
      final list = <TechNodePosition>[];

      if (layer == maxLayer) {
        for (var i = 0; i < ids.length; i++) {
          list.add(
            TechNodePosition(
              techId: ids[i],
              x: x,
              y: 24 + i * _rowGap,
              layer: layer,
            ),
          );
        }
      } else {
        // Reserved row indices: rows that must be left free for connectors from left layers to right layers.
        final reserved = <int>{};
        for (var rightLayer = layer + 1; rightLayer <= maxLayer; rightLayer++) {
          for (final pos in positionsByLayer[rightLayer]!) {
            final tech = catalog[pos.techId];
            if (tech == null) continue;
            final hasPrereqLeft = tech.prerequisiteIds.any(
              (pr) => (layerByTech[pr] ?? -1) < layer,
            );
            if (hasPrereqLeft) {
              final rowIndex = ((pos.y - 24) / _rowGap).round();
              reserved.add(rowIndex);
            }
          }
        }
        final totalRows = reserved.isEmpty
            ? ids.length
            : math.max(
                ids.length + reserved.length,
                reserved.reduce(math.max) + 1,
              );
        final nonReserved = List<int>.generate(
          totalRows,
          (i) => i,
        ).where((i) => !reserved.contains(i)).toList()..sort();
        for (var i = 0; i < ids.length; i++) {
          final rowIndex = nonReserved[i];
          list.add(
            TechNodePosition(
              techId: ids[i],
              x: x,
              y: 24 + rowIndex * _rowGap,
              layer: layer,
            ),
          );
        }
      }
      positionsByLayer[layer] = list;
    }

    final positions = <TechNodePosition>[];
    for (var layer = 0; layer <= maxLayer; layer++) {
      positions.addAll(positionsByLayer[layer]!);
    }
    return positions;
  }

  void _showTechDialog(BuildContext context, TechDefinition tech) {
    final l10n = appL10n(context);
    final effects = _effectSummaryLines(l10n, tech);
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => CtDialogShell(
        maxWidth: 420,
        maxHeight: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(techDisplayName(tech.id), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.techTree_eraCategory(
                        _eraRoman(tech.era),
                        _categoryLabelL10n(l10n, tech.category),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.techTree_researchPoints(tech.cost),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (tech.prerequisiteIds.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.techTree_prerequisites,
                        style: theme.textTheme.labelLarge,
                      ),
                      ...tech.prerequisiteIds.map(
                        (id) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            l10n.techTree_prerequisiteBullet(
                              techDisplayName(id),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                    if (effects.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.techTree_effects,
                        style: theme.textTheme.labelLarge,
                      ),
                      ...effects.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            l10n.techTree_bulletItem(e),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: CtNinePatchButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.common_close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _eraRoman(int era) {
    const romans = ['I', 'II', 'III', 'IV'];
    return era >= 1 && era <= romans.length ? romans[era - 1] : '$era';
  }

  static String _categoryLabelL10n(AppLocalizations l10n, String category) {
    return switch (category) {
      'gathering' => l10n.techTree_categoryGathering,
      'transport' => l10n.techTree_categoryTransport,
      'labour' => l10n.techTree_categoryLabour,
      'civilian' => l10n.techTree_categoryCivilian,
      'diplomacy' => l10n.techTree_categoryDiplomacy,
      'naval' => l10n.techTree_categoryNaval,
      'military' => l10n.techTree_categoryMilitary,
      'new-world' => l10n.techTree_categoryNewWorld,
      _ => category,
    };
  }

  static List<String> _effectSummaryLines(
    AppLocalizations l10n,
    TechDefinition tech,
  ) {
    final list = <String>[];
    for (final rid in tech.regimentUnlockIds) {
      list.add(l10n.techEffect_unlocksRegiment(_humanizeId(rid)));
    }
    for (final sid in tech.shipUnlockIds) {
      list.add(l10n.techEffect_unlocksShip(_humanizeId(sid)));
    }
    for (final lineId in techEffectSummaryLineIdsFor(tech.id)) {
      list.add(lookupTechEffectSummaryLine(l10n, lineId));
    }
    if (list.isEmpty) {
      list.add(
        l10n.techEffect_fallbackCategoryImprovement(
          _categoryLabelL10n(l10n, tech.category),
        ),
      );
    }
    return list;
  }

  static String _humanizeId(String id) {
    if (id.isEmpty) return id;
    return id
        .split('_')
        .map(
          (s) => s.isEmpty
              ? s
              : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _TechNodeState {
  const _TechNodeState({
    required this.researched,
    required this.inProgress,
    required this.available,
  });
  final bool researched;
  final bool inProgress;
  final bool available;
}

class _TechTreeEdgePainter extends CustomPainter {
  _TechTreeEdgePainter({required this.positions});

  final List<TechNodePosition> positions;

  static double get _centerY => _nodeHeight / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final posByTech = {for (final p in positions) p.techId: p};
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = _edgeStrokeWidth
      ..style = PaintingStyle.stroke;

    for (final tech in techCatalog.values) {
      final toPos = posByTech[tech.id];
      if (toPos == null) continue;
      final toLeftX = toPos.x;
      final toCenterY = toPos.y + _centerY;
      for (final prereqId in tech.prerequisiteIds) {
        final fromPos = posByTech[prereqId];
        if (fromPos == null) continue;
        final fromRightX = fromPos.x + _nodeWidth;
        final fromCenterY = fromPos.y + _centerY;

        // Right-angled connector: horizontal into gap, vertical to target row, horizontal to target.
        // Layout reserves a row slot in intermediate columns so this segment does not pass through nodes.
        final bendX = fromRightX + _edgeBendOffset;
        final path = Path()
          ..moveTo(fromRightX, fromCenterY)
          ..lineTo(bendX, fromCenterY)
          ..lineTo(bendX, toCenterY)
          ..lineTo(toLeftX, toCenterY);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TechNode extends StatelessWidget {
  const _TechNode({
    required this.tech,
    required this.state,
    required this.onTap,
  });

  final TechDefinition tech;
  final _TechNodeState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[tech.category] ?? Colors.grey;
    final bool locked =
        !state.researched && !state.inProgress && !state.available;

    Color fillColor;
    Color borderColor;
    double borderWidth;
    if (state.researched) {
      fillColor = color;
      borderColor = color.withValues(alpha: 0.8);
      borderWidth = 2;
    } else if (state.inProgress) {
      fillColor = color.withValues(alpha: 0.4);
      borderColor = color;
      borderWidth = 3;
    } else if (state.available) {
      fillColor = color.withValues(alpha: 0.15);
      borderColor = color;
      borderWidth = 2;
    } else {
      fillColor = Colors.grey.shade200;
      borderColor = Colors.grey.shade400;
      borderWidth = 1;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: _nodeWidth,
          height: _nodeHeight,
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_categoryIcons.containsKey(tech.category))
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: StrictAssetIcon(
                        assetPath: _categoryIcons[tech.category]!,
                        width: 16,
                        height: 16,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      techDisplayName(tech.id),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: locked ? Colors.grey : null,
                        fontWeight: state.researched ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row label for tech tree legend samples (maps to [AppLocalizations] state strings).
enum _TechLegendStateKind { researched, inProgress, available, locked }

class _TechTreeLegend extends StatelessWidget {
  const _TechTreeLegend({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.techTree_legendTitle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _categoryColors.entries
              .map(
                (e) => _LegendChip(
                  color: e.value,
                  label: TechTreeWidget._categoryLabelL10n(l10n, e.key),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _StateLegendSample(
              kind: _TechLegendStateKind.researched,
              state: _TechNodeState(
                researched: true,
                inProgress: false,
                available: false,
              ),
            ),
            _StateLegendSample(
              kind: _TechLegendStateKind.inProgress,
              state: _TechNodeState(
                researched: false,
                inProgress: true,
                available: false,
              ),
            ),
            _StateLegendSample(
              kind: _TechLegendStateKind.available,
              state: _TechNodeState(
                researched: false,
                inProgress: false,
                available: true,
              ),
            ),
            _StateLegendSample(
              kind: _TechLegendStateKind.locked,
              state: _TechNodeState(
                researched: false,
                inProgress: false,
                available: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color, width: 1.5),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _StateLegendSample extends StatelessWidget {
  const _StateLegendSample({required this.kind, required this.state});

  final _TechLegendStateKind kind;
  final _TechNodeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    // Use a dummy tech with neutral category just to render the style.
    const dummyTech = TechDefinition(
      id: 'legend_dummy',
      era: 1,
      category: 'gathering',
      cost: 0,
      prerequisiteIds: <String>[],
      regimentUnlockIds: <String>[],
      shipUnlockIds: <String>[],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 24,
          child: _TechNode(tech: dummyTech, state: state, onTap: () {}),
        ),
        const SizedBox(width: 4),
        Text(
          _localizedLabel(l10n),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _localizedLabel(AppLocalizations l10n) {
    return switch (kind) {
      _TechLegendStateKind.researched => l10n.techTree_stateResearched,
      _TechLegendStateKind.inProgress => l10n.techTree_stateInProgress,
      _TechLegendStateKind.available => l10n.techTree_stateAvailable,
      _TechLegendStateKind.locked => l10n.techTree_stateLocked,
    };
  }
}
