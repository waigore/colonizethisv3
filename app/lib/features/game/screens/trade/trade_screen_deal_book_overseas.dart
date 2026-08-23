import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_section_label.dart';
import '../../widgets/production/commodity_ui_helpers.dart';
import 'trade_screen_contract_deal_book.dart';

class DealBookOverseasProfitLedgerSection extends StatelessWidget {
  const DealBookOverseasProfitLedgerSection({
    super.key,
    required this.records,
    required this.l10n,
  });

  final List<OverseasProfitCreditRecord> records;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle rowStyle =
        (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CtSectionLabel(l10n.tradeDealBook_overseasProfitHeading),
          const SizedBox(height: 4),
          for (int i = 0; i < records.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
              child: Text(
                l10n.tradeDealBook_overseasProfitRow(
                  commodityDisplayName(l10n, records[i].commodityId),
                  records[i].quantity,
                  records[i].profitTreasury,
                ),
                key: TradeScreenDealBookKeys.dealBookOverseasProfitRowKey(i),
                style: rowStyle,
              ),
            ),
        ],
      ),
    );
  }
}
