// Wide-layout deferred MAP20001 sections (Refs #4690 Slice C).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'province_sea_zone_detail_overlay_support.dart';

/// Defers [builder] until this widget mounts (narrow lazy tabs).
class OverlayDeferredSectionBody extends StatelessWidget {
  const OverlayDeferredSectionBody({required this.builder});

  final Widget Function() builder;

  @override
  Widget build(BuildContext context) => builder();
}

/// One wide-layout section: [title] for the deferred header shell and [builder]
/// for the full section body once revealed.
class OverlaySectionSpec {
  const OverlaySectionSpec({required this.title, required this.builder});

  final String title;
  final Widget Function() builder;
}

/// Builds Political + Tile eagerly; defers later section bodies until scroll.
class ProvinceOverlayWideLazySections extends StatefulWidget {
  const ProvinceOverlayWideLazySections({
    super.key,
    required this.sections,
    this.eagerSectionCount = 2,
  });

  final List<OverlaySectionSpec> sections;
  final int eagerSectionCount;

  @override
  State<ProvinceOverlayWideLazySections> createState() =>
      ProvinceOverlayWideLazySectionsState();
}

class ProvinceOverlayWideLazySectionsState
    extends State<ProvinceOverlayWideLazySections> {
  late Set<int> _revealedIndices;

  @override
  void initState() {
    super.initState();
    _revealedIndices = {
      for (var i = 0; i < widget.eagerSectionCount && i < widget.sections.length; i++)
        i,
    };
  }

  void _reveal(int index) {
    if (_revealedIndices.contains(index)) return;
    setState(() => _revealedIndices.add(index));
  }

  void handleScroll(ScrollMetrics metrics) {
    _revealDeferredOnScroll(metrics);
    _scheduleDeferredVisibilityChecks();
  }

  void _revealDeferredOnScroll(ScrollMetrics metrics) {
    if (metrics.pixels <= 0) return;
    final pending = <int>[
      for (var i = widget.eagerSectionCount; i < widget.sections.length; i++)
        if (!_revealedIndices.contains(i)) i,
    ];
    if (pending.isEmpty) return;
    setState(() => _revealedIndices.addAll(pending));
  }

  void _scheduleDeferredVisibilityChecks() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var i = widget.eagerSectionCount; i < widget.sections.length; i++) {
        if (_revealedIndices.contains(i)) continue;
        final key = _deferredKeys[i];
        if (key?.currentContext != null && _isAnchorVisible(key!.currentContext!)) {
          _reveal(i);
        }
      }
    });
  }

  final Map<int, GlobalKey> _deferredKeys = {};

  GlobalKey _keyFor(int index) =>
      _deferredKeys.putIfAbsent(index, GlobalKey.new);

  bool _isAnchorVisible(BuildContext anchorContext) {
    final box = anchorContext.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;

    final position = box.localToGlobal(Offset.zero);
    final viewportHeight = MediaQuery.sizeOf(anchorContext).height;
    return position.dy + box.size.height > 0 && position.dy < viewportHeight;
  }

  @override
  Widget build(BuildContext context) {
    _scheduleDeferredVisibilityChecks();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.sections.length; i++) _buildSection(i),
      ],
    );
  }

  Widget _buildSection(int index) {
    final spec = widget.sections[index];
    if (_revealedIndices.contains(index)) {
      return spec.builder();
    }
    return KeyedSubtree(
      key: _keyFor(index),
      child: buildOverlaySection(spec.title, const SizedBox.shrink()),
    );
  }
}
