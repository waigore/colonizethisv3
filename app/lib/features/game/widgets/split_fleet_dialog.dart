import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';

class ShipTransfer {
  ShipTransfer({required this.typeId, required this.count});
  final String typeId;
  final int count;
}

class SplitFleetDialog extends StatefulWidget {
  const SplitFleetDialog({
    super.key,
    required this.originalFleet,
    required this.game,
    required this.humanPlayerId,
    required this.onConfirm,
    required this.isHomeFleet,
  });

  final Fleet originalFleet;
  final Game game;
  final String humanPlayerId;
  final void Function(List<String> shipsToNewFleet) onConfirm;
  final bool isHomeFleet;

  @override
  State<SplitFleetDialog> createState() => _SplitFleetDialogState();
}

class _SplitFleetDialogState extends State<SplitFleetDialog> {
  static const double _panelListHeight = 150;
  late Map<String, int> _originalCounts;
  late Map<String, int> _newCounts;
  String? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    _initializeCounts();
  }

  void _initializeCounts() {
    _originalCounts = {};
    _newCounts = {};
    _selectedTypeId = null;
    for (final typeId in widget.originalFleet.shipTypeIds) {
      _originalCounts[typeId] = (_originalCounts[typeId] ?? 0) + 1;
    }
  }

  int get _totalOriginal {
    return _originalCounts.values.fold(0, (sum, count) => sum + count);
  }

  int get _totalNew {
    return _newCounts.values.fold(0, (sum, count) => sum + count);
  }

  bool get _canConfirm {
    if (widget.isHomeFleet) {
      return _totalNew > 0;
    }
    return _totalOriginal >= 1 && _totalNew > 0;
  }

  String _fleetLocationLabel() {
    final fleet = widget.originalFleet;
    if (fleet.isAtSea) {
      final seaZoneId = fleet.seaZoneId!;
      final localId = seaZoneId.contains('|')
          ? seaZoneId.split('|').last
          : seaZoneId;
      return 'Region — $localId';
    } else if (fleet.isInPort) {
      final inPortId = fleet.inPortAtProvinceId!;
      final provinceMap = <String, Province>{};
      for (final p in widget.game.worldState.oldWorld.provinces) {
        provinceMap[p.id] = p;
        provinceMap['${p.regionId}|${p.id}'] = p;
      }
      for (final p in widget.game.worldState.newWorld.provinces) {
        provinceMap[p.id] = p;
        provinceMap['${p.regionId}|${p.id}'] = p;
      }
      final province = provinceMap[inPortId];
      final regionId = fleet.regionId;
      final regionLabel = regionId == 'oldWorld' ? 'Old World' : 'New World';
      final provinceName = province?.displayName ?? inPortId;
      return '$provinceName — $regionLabel';
    }
    return 'Unknown';
  }

  void _moveToNew(String typeId) {
    setState(() {
      final count = _originalCounts[typeId] ?? 0;
      if (count > 0) {
        _originalCounts[typeId] = count - 1;
        _newCounts[typeId] = (_newCounts[typeId] ?? 0) + 1;
        _cleanupZeros();
      }
    });
  }

  void _moveToOriginal(String typeId) {
    setState(() {
      final count = _newCounts[typeId] ?? 0;
      if (count > 0) {
        _newCounts[typeId] = count - 1;
        _originalCounts[typeId] = (_originalCounts[typeId] ?? 0) + 1;
        _cleanupZeros();
      }
    });
  }

  void _moveAllToNew(String typeId) {
    setState(() {
      final count = _originalCounts[typeId] ?? 0;
      if (count > 0) {
        _newCounts[typeId] = (_newCounts[typeId] ?? 0) + count;
        _originalCounts.remove(typeId);
      }
    });
  }

  void _moveAllToOriginal(String typeId) {
    setState(() {
      final count = _newCounts[typeId] ?? 0;
      if (count > 0) {
        _originalCounts[typeId] = (_originalCounts[typeId] ?? 0) + count;
        _newCounts.remove(typeId);
      }
    });
  }

  void _cleanupZeros() {
    _originalCounts.removeWhere((_, v) => v == 0);
    _newCounts.removeWhere((_, v) => v == 0);
    final selected = _selectedTypeId;
    if (selected != null &&
        !_originalCounts.containsKey(selected) &&
        !_newCounts.containsKey(selected)) {
      _selectedTypeId = null;
    }
  }

  void _toggleSelection(String typeId) {
    setState(() {
      _selectedTypeId = _selectedTypeId == typeId ? null : typeId;
    });
  }

  void _moveSelectedToOriginal() {
    final selected = _selectedTypeId;
    if (selected == null) return;
    _moveToOriginal(selected);
  }

  void _moveSelectedToNew() {
    final selected = _selectedTypeId;
    if (selected == null) return;
    _moveToNew(selected);
  }

  void _moveAllSelectedToOriginal() {
    final selected = _selectedTypeId;
    if (selected == null) return;
    _moveAllToOriginal(selected);
  }

  void _moveAllSelectedToNew() {
    final selected = _selectedTypeId;
    if (selected == null) return;
    _moveAllToNew(selected);
  }

  void _handleConfirm() {
    if (!_canConfirm) return;
    final shipsToNewFleet = <String>[];
    for (final entry in _newCounts.entries) {
      for (var i = 0; i < entry.value; i++) {
        shipsToNewFleet.add(entry.key);
      }
    }
    widget.onConfirm(shipsToNewFleet);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedTypeId;
    final selectedInOriginal = selected == null ? 0 : (_originalCounts[selected] ?? 0);
    final selectedInNew = selected == null ? 0 : (_newCounts[selected] ?? 0);

    return CtDialogShell(
      maxWidth: 520,
      maxHeight: 500,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Split Fleet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FleetPanel(
                    title: widget.originalFleet.id == 'home_fleet'
                        ? 'Home Fleet'
                        : 'Fleet ${widget.originalFleet.id}',
                    location: _fleetLocationLabel(),
                    counts: _originalCounts,
                    total: _totalOriginal,
                    listHeight: _panelListHeight,
                    selectedTypeId: _selectedTypeId,
                    onSelectType: _toggleSelection,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FleetPanel(
                    title: 'New Fleet',
                    location: _fleetLocationLabel(),
                    counts: _newCounts,
                    total: _totalNew,
                    listHeight: _panelListHeight,
                    selectedTypeId: _selectedTypeId,
                    onSelectType: _toggleSelection,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CtNinePatchButton(
                  onPressed: _moveAllSelectedToOriginal,
                  enabled: selected != null && selectedInNew > 0,
                  child: const Text('<<'),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
                  onPressed: _moveSelectedToOriginal,
                  enabled: selected != null && selectedInNew > 0,
                  child: const Text('<'),
                ),
                const SizedBox(width: 16),
                CtNinePatchButton(
                  onPressed: _moveSelectedToNew,
                  enabled: selected != null && selectedInOriginal > 0,
                  child: const Text('>'),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
                  onPressed: _moveAllSelectedToNew,
                  enabled: selected != null && selectedInOriginal > 0,
                  child: const Text('>>'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CtNinePatchButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
                  onPressed: _handleConfirm,
                  enabled: _canConfirm,
                  child: const Text('Confirm Split'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FleetPanel extends StatelessWidget {
  const _FleetPanel({
    required this.title,
    required this.location,
    required this.counts,
    required this.total,
    required this.listHeight,
    required this.selectedTypeId,
    required this.onSelectType,
  });

  final String title;
  final String location;
  final Map<String, int> counts;
  final int total;
  final double listHeight;
  final String? selectedTypeId;
  final void Function(String typeId) onSelectType;

  @override
  Widget build(BuildContext context) {
    final sortedTypes = counts.keys.toList()..sort();

    return CtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Text(location, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          SizedBox(
            height: listHeight,
            child: sortedTypes.isEmpty
                ? Center(
                    child: Text(
                      'No ships',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedTypes.length,
                    itemBuilder: (context, index) {
                      final typeId = sortedTypes[index];
                      final count = counts[typeId] ?? 0;
                      final isSelected = selectedTypeId == typeId;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Material(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => onSelectType(typeId),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Text('$typeId ($count)'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 4),
          Text(
            'Total: $total ships',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
