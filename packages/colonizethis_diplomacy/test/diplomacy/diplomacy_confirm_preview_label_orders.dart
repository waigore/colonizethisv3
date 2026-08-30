import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_confirm_preview_cases.dart' show previewTargetGp, previewMinorId;

List<DiplomaticOrder> structuredLabelOrders() => const [
  DiplomaticOrder(
    type: DiplomaticOrderType.declareWar,
    targetFactionId: previewTargetGp,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.offerPeace,
    targetFactionId: previewTargetGp,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.alliance,
    targetFactionId: previewTargetGp,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.breakAlliance,
    targetFactionId: previewTargetGp,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishFtp,
    targetFactionId: previewTargetGp,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.boycott,
    targetFactionId: previewTargetGp,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.revokeBoycott,
    targetFactionId: previewTargetGp,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.grantAid,
    targetFactionId: previewMinorId,
    amount: 1000,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.setSubsidy,
    targetFactionId: previewMinorId,
    amount: 10,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: previewMinorId,
    overtureStage: OvertureStage.tradeConsulate,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: previewMinorId,
    overtureStage: OvertureStage.embassy,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: previewMinorId,
    overtureStage: OvertureStage.nap,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: previewMinorId,
    overtureStage: OvertureStage.joinEmpire,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: previewTargetGp,
    overtureStage: OvertureStage.joinEmpire,
  ),
];
