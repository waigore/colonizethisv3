// Treasury / peasants / commodity chip resource bar for commodity-cost train
// dialogs. SPEC/ui/components/train-dialog-chrome.md.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../widgets/resource_icon.dart';
import '../production/commodity_ui_helpers.dart';
import 'train_dialog_chrome.dart';

/// Treasury / peasants / commodity chip resource bar shared by the military and
/// naval train dialogs (icon chips, not the civilian label/value entry bar).
class CommodityCostTrainDialogResourceBar extends StatelessWidget {
  const CommodityCostTrainDialogResourceBar({
    super.key,
    required this.treasury,
    required this.remainingTreasury,
    required this.peasants,
    required this.remainingPeasants,
    required this.stockpile,
    required this.committedCommodities,
    required this.commodityIds,
    required this.deficitHint,
    required this.l10n,
  });

  final int treasury;
  final int remainingTreasury;
  final int peasants;
  final int remainingPeasants;
  final Map<String, int> committedCommodities;
  final Stockpile stockpile;
  final List<String> commodityIds;
  final String? deficitHint;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrainDialogResourceBarBox(
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _buildTreasuryChip(),
              _buildPeasantsChip(),
              for (final commodityId in commodityIds)
                _buildCommodityChip(commodityId),
            ],
          ),
        ),
        ..._buildDeficitHint(context),
      ],
    );
  }

  Widget _buildTreasuryChip() {
    return TrainDialogResourceChip(
      child: Text(
        l10n.trainUnits_treasury(
          '${formatTreasuryCurrency(remainingTreasury)} / '
          '${formatTreasuryCurrency(treasury)}',
        ),
      ),
    );
  }

  Widget _buildPeasantsChip() {
    return TrainDialogResourceChip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WorkerIcon(workerType: 'peasant', size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.trainUnits_peasantsValue('$remainingPeasants / $peasants'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommodityChip(String commodityId) {
    return TrainDialogResourceChip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResourceIcon(commodityId: commodityId, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.trainMilitary_commodityValue(
                commodityDisplayName(l10n, commodityId),
                '${stockpile.quantityOf(commodityId) - (committedCommodities[commodityId] ?? 0)}'
                ' / ${stockpile.quantityOf(commodityId)}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeficitHint(BuildContext context) {
    if (deficitHint == null) return const [];
    return [
      const SizedBox(height: 4),
      Text(
        deficitHint!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: EditorialMonoclePalette.danger,
        ),
      ),
    ];
  }
}
