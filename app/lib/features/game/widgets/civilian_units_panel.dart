// Civilian units panel. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

/// Human-readable label for work target ids. SPEC/ui/civilian-units-panel.md.
const Map<String, String> _workTargetLabels = {
  'explore': 'Explore',
  'prospect': 'Prospect',
  'build_improvement': 'Build improvement',
  'upgrade_town': 'Upgrade town',
  'build_road': 'Build road',
  'build_port': 'Build port',
  'build_fort': 'Build fort',
  'build_rail': 'Build rail',
  'steal_tech': 'Steal tech',
  'counter_spy': 'Counter spy',
  'purchase_land': 'Purchase land',
};

/// Region id to display label. SPEC/ui/civilian-units-panel.md.
String _regionLabel(String regionId) {
  switch (regionId) {
    case 'oldWorld':
      return 'Old World';
    case 'newWorld':
      return 'New World';
    default:
      return regionId;
  }
}

/// Builds prefixed province id -> province display name from [game].
Map<String, String> _provinceNamesByPrefixedId(Game game) {
  final out = <String, String>{};
  for (final p in game.worldState.oldWorld.provinces) {
    out['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
  }
  for (final p in game.worldState.newWorld.provinces) {
    out['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
  }
  return out;
}

/// Returns true if [unit] is a civilian (not military, not naval). SPEC/game/civilian-units.md.
bool _isCivilianUnit(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}

/// Civilian units for one region, sorted by province name then type then id.
List<Unit> _civilianUnitsInRegion(
  List<Unit> units,
  String humanPlayerId,
  Map<String, String> provinceNames,
) {
  final list = units
      .where((u) => u.ownerId == humanPlayerId && u.tileKey != null && _isCivilianUnit(u))
      .toList();
  list.sort((a, b) {
    final provA = Unit.provinceIdFromTileKey(a.tileKey);
    final provB = Unit.provinceIdFromTileKey(b.tileKey);
    final regionA = Unit.regionIdFromTileKey(a.tileKey) ?? '';
    final regionB = Unit.regionIdFromTileKey(b.tileKey) ?? '';
    final prefixedA = '$regionA|$provA';
    final prefixedB = '$regionB|$provB';
    final nameA = provinceNames[prefixedA] ?? prefixedA;
    final nameB = provinceNames[prefixedB] ?? prefixedB;
    final nameCmp = nameA.compareTo(nameB);
    if (nameCmp != 0) return nameCmp;
    final typeCmp = a.type.compareTo(b.type);
    if (typeCmp != 0) return typeCmp;
    return a.id.compareTo(b.id);
  });
  return list;
}

/// Panel that lists all civilian units for the human player. SPEC/ui/civilian-units-panel.md.
class CivilianUnitsPanel extends StatelessWidget {
  const CivilianUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    this.onLocateUnit,
  });

  final Game game;
  final String humanPlayerId;
  /// Called when the user taps a unit row; [unit] has non-null [Unit.tileKey].
  final void Function(Unit unit)? onLocateUnit;

  @override
  Widget build(BuildContext context) {
    final provinceNames = _provinceNamesByPrefixedId(game);
    final ow = _civilianUnitsInRegion(
      game.worldState.oldWorld.units,
      humanPlayerId,
      provinceNames,
    );
    final nw = _civilianUnitsInRegion(
      game.worldState.newWorld.units,
      humanPlayerId,
      provinceNames,
    );
    final hasAny = ow.isNotEmpty || nw.isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Civilian Units',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: hasAny
                  ? ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      children: [
                        if (ow.isNotEmpty) ...[
                          _RegionHeader(label: _regionLabel('oldWorld')),
                          ...ow.map((u) => _UnitRow(
                                unit: u,
                                provinceNames: provinceNames,
                                onTap: onLocateUnit != null && u.tileKey != null
                                    ? () => onLocateUnit!(u)
                                    : null,
                              )),
                        ],
                        if (nw.isNotEmpty) ...[
                          _RegionHeader(label: _regionLabel('newWorld')),
                          ...nw.map((u) => _UnitRow(
                                unit: u,
                                provinceNames: provinceNames,
                                onTap: onLocateUnit != null && u.tileKey != null
                                    ? () => onLocateUnit!(u)
                                    : null,
                              )),
                        ],
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No civilian units',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionHeader extends StatelessWidget {
  const _RegionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.provinceNames,
    this.onTap,
  });

  final Unit unit;
  final Map<String, String> provinceNames;
  final VoidCallback? onTap;

  String _locationLabel() {
    final regionId = Unit.regionIdFromTileKey(unit.tileKey);
    final provinceId = Unit.provinceIdFromTileKey(unit.tileKey);
    if (regionId == null || provinceId == null) return '—';
    final prefixed = '$regionId|$provinceId';
    final name = provinceNames[prefixed] ?? prefixed;
    final regionLabel = _regionLabel(regionId);
    return '$regionLabel — $name';
  }

  String _assignedToLabel() {
    if (unit.status != UnitStatus.working || unit.currentWork == null) {
      return '—';
    }
    final cw = unit.currentWork!;
    final workLabel = _workTargetLabels[cw.workTarget] ?? cw.workTarget;
    final regionId = Unit.regionIdFromTileKey(cw.tileKey);
    final provinceId = Unit.provinceIdFromTileKey(cw.tileKey);
    String location = '';
    if (regionId != null && provinceId != null) {
      final name = provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
      location = ' (${_regionLabel(regionId)} — $name)';
    }
    final progress = cw.totalTurns > 0
        ? ' ${cw.remainingTurns}/${cw.totalTurns} turns'
        : '';
    return '$workLabel$location$progress';
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (unit.status) {
      UnitStatus.idle => 'Idle',
      UnitStatus.working => 'Working',
      UnitStatus.done => 'Done',
    };
    return ListTile(
      title: Text(unit.type),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Status: $statusLabel'),
          Text('Location: ${_locationLabel()}'),
          Text('Assigned to: ${_assignedToLabel()}'),
        ],
      ),
      dense: true,
      onTap: onTap,
    );
  }
}
