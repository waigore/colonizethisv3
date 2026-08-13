/// Market tab layout keys and wide-grid spacing (Refs #4352).
library;

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';

abstract final class TradeScreenMarketLayoutKeys {
  TradeScreenMarketLayoutKeys._();

  /// Content width at which Market commodity rows render in a two-column
  /// row-major grid with compact two-line rows (Refs #4227). Matches
  /// [kNarrowBreakpoint] and [TradeScreenDealBookKeys.dealBookTwoPanelMinWidth].
  static const double marketTwoColumnMinWidth = kNarrowBreakpoint;

  /// Horizontal gap between the two Market commodity columns on wide
  /// layouts (Refs #4227). Matches Deal Book inter-panel gap.
  static const double marketGridColumnGap = 12;

  /// Vertical gap between Market commodity grid rows within a section on
  /// wide layouts (Refs #4227).
  static const double marketGridRowGap = 6;

  /// Stable widget key for the `Food` category section header.
  static const Key marketSectionFoodKey =
      ValueKey<String>('tradeScreenMarketSection:food');

  /// Stable widget key for the `Raw Materials` category section header.
  static const Key marketSectionRawMaterialsKey =
      ValueKey<String>('tradeScreenMarketSection:rawMaterials');

  /// Stable widget key for the `Manufactured` category section header.
  static const Key marketSectionManufacturedKey =
      ValueKey<String>('tradeScreenMarketSection:manufactured');
}
