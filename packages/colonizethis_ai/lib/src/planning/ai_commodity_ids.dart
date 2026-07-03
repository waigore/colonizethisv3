/// Canonical commodity ids referenced across AI economy/growth planners.
///
/// Single home for the fabric / cast-iron / lumber ids that were previously
/// inlined via `CommodityCatalog.<name>.id` at multiple planner sites (Refs
/// #3822). Values match `CommodityCatalog` / SPEC/game/commodity-catalog.md.
abstract final class kAiCommodityIds {
  static const fabric = 'fabric';
  static const castIron = 'castIron';
  static const lumber = 'lumber';
}
