// Shared stockpile helper for below-quota peace treasury recovery pins.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Stockpile goldStockpile(int qty) => qty <= 0
    ? const Stockpile()
    : Stockpile().applyDelta(CommodityCatalog.gold.id, qty);
