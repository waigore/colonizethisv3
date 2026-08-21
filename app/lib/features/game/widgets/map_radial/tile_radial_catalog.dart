/// Ranking for MAP30001 / MAP30002 Tile-shortcut spokes.
///
/// SPEC: `SPEC/ui/components/tile-radial-catalog.md` (Refs #4440, #4570).
library;

/// Overlay civilian work shortcuts the radial may show. Not a general order catalog.
enum TileRadialCatalogAction {
  explore,
  prospect,
  buildImprovement,
  buildRoad,
  purchaseLand,
  upgradeTown,
  buildPort,
  buildRail,
  buildFort,
}

/// One conceivable catalog action after enablement ranking.
class TileRadialSpoke {
  const TileRadialSpoke({required this.action, required this.enabled});

  final TileRadialCatalogAction action;
  final bool enabled;
}

/// Wedges on `MAP30001` plus remainder rows for `MAP30002`.
class TileRadialCatalogLayout {
  const TileRadialCatalogLayout({
    required this.wedges,
    required this.moreRemainder,
  });

  final List<TileRadialSpoke> wedges;
  final List<TileRadialSpoke> moreRemainder;
}

/// Visibility for one catalog action (overlay `showIcon` / `enabled`).
typedef TileRadialActionVisibility = ({bool showIcon, bool enabled});

const int kTileRadialMaxActionWedges = 5;

const List<TileRadialCatalogAction> kTileRadialCatalogOrder =
    <TileRadialCatalogAction>[
      TileRadialCatalogAction.explore,
      TileRadialCatalogAction.prospect,
      TileRadialCatalogAction.buildImprovement,
      TileRadialCatalogAction.buildRoad,
      TileRadialCatalogAction.purchaseLand,
      TileRadialCatalogAction.upgradeTown,
      TileRadialCatalogAction.buildPort,
      TileRadialCatalogAction.buildRail,
      TileRadialCatalogAction.buildFort,
    ];

/// Filters to `showIcon` actions, sorts enabled first, then catalog order,
/// and caps wedges at [maxWedges].
TileRadialCatalogLayout rankTileRadialCatalog({
  required Map<TileRadialCatalogAction, TileRadialActionVisibility> visibility,
  int maxWedges = kTileRadialMaxActionWedges,
}) {
  final items = <TileRadialSpoke>[
    for (final action in kTileRadialCatalogOrder)
      if (visibility[action]?.showIcon == true)
        TileRadialSpoke(
          action: action,
          enabled: visibility[action]!.enabled,
        ),
  ];
  items.sort((a, b) {
    final byEnabled = (b.enabled ? 1 : 0) - (a.enabled ? 1 : 0);
    if (byEnabled != 0) return byEnabled;
    return kTileRadialCatalogOrder
        .indexOf(a.action)
        .compareTo(kTileRadialCatalogOrder.indexOf(b.action));
  });
  if (items.length <= maxWedges) {
    return TileRadialCatalogLayout(wedges: items, moreRemainder: const []);
  }
  return TileRadialCatalogLayout(
    wedges: items.sublist(0, maxWedges),
    moreRemainder: items.sublist(maxWedges),
  );
}
