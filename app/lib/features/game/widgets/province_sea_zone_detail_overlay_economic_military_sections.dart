
part of 'province_sea_zone_detail_overlay.dart';

/// Shared empty-state placeholder body used by the Economic, Military,
/// Civilian, and Naval sections when their content list is empty.
///
/// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
/// § Style / implementation — Dark-theme empty-state body tokens (S9).
///
/// `EditorialMonoclePalette.muted` is a runtime OKLCH→`Color` getter, so
/// the [TextStyle] cannot be `const`; the helper centralizes the token
/// so every empty surface stays in sync (mirroring the obfuscated
/// `???` helper's single-source pattern).
Widget _emptyBodyDashText() {
  return Text('—', style: TextStyle(color: EditorialMonoclePalette.muted));
}

Widget _buildEconomicSection({
  required AppLocalizations l10n,
  required List<String> resourceKeysSorted,
  required Map<String, List<({String tileKey, String terrain, String impBase})>>
  byResImproved,
  required Map<String, List<({String tileKey, String terrain})>>
  byResImprovable,
  void Function(String?)? onHighlightTile,
}) {
  final children = <Widget>[];

  for (final resId in resourceKeysSorted) {
    final improved = byResImproved[resId] ?? const [];
    for (final row in improved) {
      children.add(
        _economicHoverRow(
          tileKey: row.tileKey,
          onHighlightTile: onHighlightTile,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResourceLabelInline(
                commodityId: resId,
                labelStyle: TextStyle(color: EditorialMonoclePalette.fg),
              ),
              const SizedBox(width: CtSpacing.m / 2),
              Expanded(
                child: Text(
                  l10n.province_economic_resourceRow(
                    row.terrain,
                    resId,
                    l10n.province_economic_withImprovement(row.impBase),
                  ),
                  style: TextStyle(color: EditorialMonoclePalette.fg),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final improvable = byResImprovable[resId] ?? const [];
    for (final row in improvable) {
      children.add(
        _economicHoverRow(
          tileKey: row.tileKey,
          onHighlightTile: onHighlightTile,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResourceLabelInline(
                commodityId: resId,
                labelStyle: TextStyle(color: EditorialMonoclePalette.muted),
              ),
              const SizedBox(width: CtSpacing.m / 2),
              Expanded(
                child: Text(
                  l10n.province_economic_resourceRow(
                    row.terrain,
                    resId,
                    l10n.province_economic_improvableSuffix,
                  ),
                  style: TextStyle(color: EditorialMonoclePalette.muted),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  if (children.isEmpty) {
    return _buildSection(l10n.provinceOverlay_sectionEconomic, _emptyBodyDashText());
  }
  return _buildSection(
    l10n.provinceOverlay_sectionEconomic,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}

Widget _buildMilitarySectionByOwner({
  required AppLocalizations l10n,
  required Game game,
  required List<Unit> military,
  required String humanPlayerId,
  required String provinceId,
  required Orders draftOrders,
}) {
  final pending = provincePanelPendingMilitaryLines(
    game: game,
    orders: draftOrders,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    l10n: l10n,
  );
  if (military.isEmpty && pending.isEmpty) {
    return _buildSection(l10n.provinceOverlay_sectionMilitary, _emptyBodyDashText());
  }
  if (military.isEmpty) {
    return _buildSection(
      l10n.provinceOverlay_sectionMilitary,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: pending
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(left: CtSpacing.m / 2),
                child: Text(
                  line,
                  style: TextStyle(color: EditorialMonoclePalette.muted),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
  final byOwner = <String, List<Unit>>{};
  for (final u in military) {
    byOwner.putIfAbsent(u.ownerId, () => []).add(u);
  }
  final ownerIds = byOwner.keys.toList()
    ..sort((a, b) {
      if (a == humanPlayerId) return -1;
      if (b == humanPlayerId) return 1;
      return _ownerName(l10n, game, a).compareTo(_ownerName(l10n, game, b));
    });
  return _buildSection(
    l10n.provinceOverlay_sectionMilitary,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...ownerIds.map((oid) {
          final list = byOwner[oid]!;
          final byType = <String, int>{};
          for (final u in list) {
            byType[u.type] = (byType[u.type] ?? 0) + 1;
          }
          final name = _ownerName(l10n, game, oid);
          return Padding(
            padding: const EdgeInsets.only(bottom: CtSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: EditorialMonoclePalette.fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ...byType.entries.map((e) {
                  final label = regimentTypeDisplayLabel(l10n, e.key);
                  return Text(
                    l10n.provinceOverlay_indentedCount(label, e.value),
                    style: TextStyle(color: EditorialMonoclePalette.fg),
                  );
                }),
              ],
            ),
          );
        }),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: CtSpacing.m / 2),
          ...pending.map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: CtSpacing.m / 2),
              child: Text(
                line,
                style: TextStyle(color: EditorialMonoclePalette.muted),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildCivilianSectionFiltered({
  required AppLocalizations l10n,
  required Game game,
  required List<Unit> civilian,
  required String humanPlayerId,
  required PlayerView playerView,
  required Orders draftOrders,
}) {
  final visible = civilian
      .where(
        (u) => foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: humanPlayerId,
          view: playerView,
        ),
      )
      .toList();
  if (visible.isEmpty) {
    return _buildSection(l10n.provinceOverlay_sectionCivilian, _emptyBodyDashText());
  }
  final workList = draftOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];
  return _buildSection(
    l10n.provinceOverlay_sectionCivilian,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: visible.map((u) {
        if (u.ownerId == humanPlayerId) {
          WorkOrder? pending;
          for (final o in workList) {
            if (o.unitId == u.id) {
              pending = o;
              break;
            }
          }
          if (pending != null) {
            final targetLabel = workOrderTargetDisplayLabel(
              l10n,
              pending.target,
            );
            return Text(
              l10n.provinceOverlay_unitTarget(u.type, targetLabel),
              style: TextStyle(color: EditorialMonoclePalette.fg),
            );
          }
          return Text(
            l10n.provinceOverlay_unitTarget(
              u.type,
              unitStatusDisplayLabel(l10n, u.status),
            ),
            style: TextStyle(color: EditorialMonoclePalette.fg),
          );
        }
        final o = _ownerName(l10n, game, u.ownerId);
        return Text(
          l10n.provinceOverlay_foreignUnitStatus(
            o,
            u.type,
            unitStatusDisplayLabel(l10n, u.status),
          ),
          style: TextStyle(color: EditorialMonoclePalette.muted),
        );
      }).toList(),
    ),
  );
}

Widget _buildNavalSection({
  required AppLocalizations l10n,
  required Game game,
  required List<Fleet> fleets,
  required String humanPlayerId,
  required Orders draftOrders,
  String? pendingNavalPortProvinceId,
}) {
  final pending = pendingNavalPortProvinceId == null
      ? const <String>[]
      : provincePanelPendingNavalLines(
          game: game,
          orders: draftOrders,
          provinceId: pendingNavalPortProvinceId,
          humanPlayerId: humanPlayerId,
          l10n: l10n,
        );
  return _buildSection(
    l10n.provinceOverlay_sectionNaval,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fleets.isEmpty && pending.isEmpty) _emptyBodyDashText(),
        if (fleets.isNotEmpty)
          ...fleets.map((f) {
            final ownerName = _ownerName(l10n, game, f.ownerId);
            final byType = <String, int>{};
            for (final s in f.ships) {
              byType[s.typeId] = (byType[s.typeId] ?? 0) + 1;
            }
            final fleetLabel = f.id == homeFleetIdFor(f.ownerId)
                ? l10n.naval_homeFleetLabel
                : l10n.naval_fleetLabel(f.id);
            final shipParts = byType.entries
                .map((e) {
                  final label = shipTypeDisplayLabel(l10n, e.key);
                  return '$label×${e.value}';
                })
                .join(', ');
            return Text(
              l10n.provinceOverlay_fleetSummary(
                ownerName,
                fleetLabel,
                shipParts,
              ),
              style: TextStyle(color: EditorialMonoclePalette.fg),
            );
          }),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: CtSpacing.m / 2),
          ...pending.map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: CtSpacing.m / 2),
              child: Text(
                line,
                style: TextStyle(color: EditorialMonoclePalette.muted),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
