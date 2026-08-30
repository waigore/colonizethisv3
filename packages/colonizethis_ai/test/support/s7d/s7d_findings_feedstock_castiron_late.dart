/// CastIron / fabric / labour S7-D findings — late sections (Refs #2847 / #4239 Slice C).
///
library;

// ignore_for_file: dangling_library_doc_comments

/// ## S7-D refresh (captured 2026-06-06 on current `dev` HEAD — castIron
///     production-assignment localization, this slice, Refs #2847)
///
/// Re-running the diagnostic on the merged `dev` HEAD (post the seller
/// feedstock-tile acquisition thread #3271–#3276 and the lumber bootstrap
/// waiver) confirms the prior re-pointed step is now reached: the owned-tile
/// extraction path **works** for gp5 / gp6 — `gpFeedstockInStockpileTurns` =
/// gp5 49 / gp6 44 (was 1) and `gpCastIronFeedstockHeldAtTurn99` shows **gp5
/// co-holds `timber` = 71 and `iron` = 64** at turn 99 (gp6 `timber` = 214 /
/// `iron` = 0; gp3 / gp4 still 0 / 0). OW gain is unchanged (gp1 / gp2 = +6
/// PASS; gp3 = +2, gp4 = +1, gp5 = +1, gp6 = +2 FAIL).
///
/// ## S7-D refresh (captured 2026-06-06 on current `dev` HEAD — castIron
///     production-assignment localization, this slice, Refs #2847)
///
/// Re-running the diagnostic on the merged `dev` HEAD (post the seller
/// feedstock-tile acquisition thread #3271–#3276 and the lumber bootstrap
/// waiver) confirms the prior re-pointed step is now reached: the owned-tile
/// extraction path **works** for gp5 / gp6 — `gpFeedstockInStockpileTurns` =
/// gp5 49 / gp6 44 (was 1) and `gpCastIronFeedstockHeldAtTurn99` shows **gp5
/// co-holds `timber` = 71 and `iron` = 64** at turn 99 (gp6 `timber` = 214 /
/// `iron` = 0; gp3 / gp4 still 0 / 0). OW gain is unchanged (gp1 / gp2 = +6
/// PASS; gp3 = +2, gp4 = +1, gp5 = +1, gp6 = +2 FAIL).
///
export 's7d_findings_feedstock_castiron_late_refresh.dart';
