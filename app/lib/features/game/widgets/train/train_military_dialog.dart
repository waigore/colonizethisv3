import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../config/routes.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../screens/counsel/military_counsel_l10n.dart';
import '../../screens/counsel/military_counsel_train_stars.dart';
import 'military_train_counsel_star.dart';
import 'train_commodity_cost_dialog_base.dart';
import 'train_dialog_base.dart';

class TrainMilitaryDialog extends TrainDialogBase {
  const TrainMilitaryDialog({
    super.key,
    required super.game,
    required super.humanPlayerId,
    required super.currentOrders,
    required super.bus,
    this.topology = const MapTopology(),
  });

  /// SPEC/ui/train-military-dialog.md — [UiScreenIds.trainMilitaryDialog].
  static const screenId = UiScreenIds.trainMilitaryDialog;

  final MapTopology topology;

  @override
  State<TrainMilitaryDialog> createState() => _TrainMilitaryDialogState();
}

class _TrainMilitaryDialogState
    extends CommodityCostTrainDialogState<TrainMilitaryDialog> {
  /// Presentation order of the military resource-bar commodity chips.
  /// SPEC/ui/train-military-dialog.md § Resource bar.
  static const _commodityIds = <String>[
    'fabric',
    'castIron',
    'lumber',
    'horses',
    'steel',
    'bronze',
  ];

  late final Map<String, MilitaryCounselRecommendation>
  _trainCounselHighlightsByUnitType = militaryCounselTrainHighlightsByUnitType(
    game: widget.game,
    playerId: widget.humanPlayerId,
    currentOrders: widget.currentOrders,
    topology: widget.topology,
  );

  @override
  bool get ordersAreMilitary => true;

  @override
  Map<String, String> get unlockingTechByUnitType => unlockingTechByRegimentId;

  @override
  String dialogTitle(AppLocalizations l10n) => l10n.trainMilitary_title;

  @override
  List<String> get resourceBarCommodityIds => _commodityIds;

  @override
  List<CommodityCostUnitEntry> get commodityCostEntries => [
    for (final e in RegimentEconomyCatalog.all)
      CommodityCostUnitEntry(
        unitTypeId: e.id,
        displayName: regimentTypeDisplayName(e.id),
        buildTreasuryCost: e.buildTreasuryCost,
        buildInputs: e.buildInputs,
      ),
  ];

  @override
  Widget? counselStarFor(CommodityCostUnitEntry entry) {
    if (isLocked(entry.unitTypeId)) return null;
    final recommendation = _trainCounselHighlightsByUnitType[entry.unitTypeId];
    if (recommendation == null) return null;
    final l10n = appL10n(context);
    final brief = militaryCounselBriefForReason(
      l10n,
      recommendation.briefReasonKey,
    );
    return MilitaryTrainCounselStar(
      briefMessage: brief,
      semanticLabel: l10n.militaryCounsel_trainStarSemantic(brief),
      onOpenCounsel: () {
        Navigator.of(context).pop();
        widget.bus.emit(
          NavigateToRouteEvent(Routes.counsel, {
            'game': widget.game,
            'humanPlayerId': widget.humanPlayerId,
            'counselTab': 'military',
            'highlightRecommendationId': recommendation.recommendationId,
          }),
        );
      },
    );
  }

  @override
  void emitCommittedOrders(List<BuildUnitOrder> orders) {
    widget.bus.emit(TrainMilitaryBuildOrdersCommittedEvent(orders: orders));
  }
}
