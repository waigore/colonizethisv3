import 'package:flutter/material.dart';

/// Widget keys for Development panel tests. SPEC/ui/development-panel.md.
abstract final class DevelopmentPanelKeys {
  DevelopmentPanelKeys._();

  static const topBarKey = Key('development_panel_top_bar');
  static const tabsBodyKey = Key('development_panel_tabs_body');
  static const overviewKey = Key('development_panel_overview');
  static const scopeListKey = Key('development_panel_scope_list');
  static const panelMapKey = Key('development_panel_map');
  static const ownedSectionKey = Key('development_panel_owned_section');
  static const purchasedSectionKey = Key('development_panel_purchased_section');

  static Key scopeRowKey(String scopeKey) =>
      Key('development_panel_scope:$scopeKey');

  static Key showButtonKey(String scopeKey, String commodityId) =>
      Key('development_panel_show:$scopeKey:$commodityId');
}
