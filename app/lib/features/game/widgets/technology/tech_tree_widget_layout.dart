// Tech tree layout helpers. Split out of `tech_tree_widget.dart` to keep the
// host file under the repo file-size target (Refs #3878).

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';

import 'tech_tree_widget_constants.dart';
import 'tech_tree_widget_types.dart';

Set<int> _reservedRowIndicesForTechLayer({
  required Map<String, TechDefinition> catalog,
  required int layer,
  required int maxLayer,
  required Map<String, int> layerByTech,
  required Map<int, List<TechNodePosition>> positionsByLayer,
}) {
  final reserved = <int>{};
  for (var rightLayer = layer + 1; rightLayer <= maxLayer; rightLayer++) {
    for (final pos in positionsByLayer[rightLayer]!) {
      final tech = catalog[pos.techId];
      if (tech == null) continue;
      final hasPrereqLeft = tech.prerequisiteIds.any(
        (pr) => (layerByTech[pr] ?? -1) < layer,
      );
      if (!hasPrereqLeft) continue;
      final rowIndex = ((pos.y - 24) / kTechTreeRowGap).round();
      reserved.add(rowIndex);
    }
  }
  return reserved;
}

double techTreeCanvasWidth(List<TechNodePosition> positions) {
  return positions.map((p) => p.x).reduce(math.max) +
      kTechTreeNodeWidth +
      48;
}

double techTreeCanvasHeight(List<TechNodePosition> positions) {
  return positions.map((p) => p.y).reduce(math.max) +
      kTechTreeNodeHeight +
      48;
}

/// Computes topological layout: each tech in a column strictly right of all its
/// prerequisites. For edges that span multiple columns, reserves a row slot in
/// each intermediate column for the connector (so the horizontal segment does
/// not pass through nodes); other techs are shifted down.
/// Used by the widget and by tests (column rule: A→B→C and A→C ⇒ B occupies
/// column between A and C).
List<TechNodePosition> computeTechTreeLayout(
  Map<String, TechDefinition> catalog,
) {
  if (catalog.isEmpty) return [];

  final layerByTech = <String, int>{};
  var maxLayer = 0;
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
    final prereqLayers =
        tech.prerequisiteIds.map((p) => layerByTech[p]!).toList();
    final layer = 1 + (prereqLayers.reduce(math.max));
    layerByTech[techId] = layer;
    if (layer > maxLayer) maxLayer = layer;
  }

  for (final id in catalog.keys) {
    assignLayer(id);
  }

  final byLayer = <int, List<String>>{};
  for (final e in layerByTech.entries) {
    byLayer.putIfAbsent(e.value, () => []).add(e.key);
  }
  for (final list in byLayer.values) {
    list.sort((a, b) => a.compareTo(b));
  }

  final positionsByLayer = <int, List<TechNodePosition>>{};
  for (var layer = maxLayer; layer >= 0; layer--) {
    final ids = byLayer[layer] ?? [];
    final x = 24.0 + layer * kTechTreeLayerGap;
    final list = <TechNodePosition>[];

    if (layer == maxLayer) {
      for (var i = 0; i < ids.length; i++) {
        list.add(
          TechNodePosition(
            techId: ids[i],
            x: x,
            y: 24 + i * kTechTreeRowGap,
            layer: layer,
          ),
        );
      }
    } else {
      final reserved = _reservedRowIndicesForTechLayer(
        catalog: catalog,
        layer: layer,
        maxLayer: maxLayer,
        layerByTech: layerByTech,
        positionsByLayer: positionsByLayer,
      );
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
            y: 24 + rowIndex * kTechTreeRowGap,
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
