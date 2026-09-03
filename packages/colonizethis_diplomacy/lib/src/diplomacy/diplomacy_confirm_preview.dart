/// First-order diplomacy confirmation copy for player commit dialogs.
/// SPEC/ui/diplomacy-panel.md § Confirmation preview; Refs #4181, #4584.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_boycott_confirm_preview.dart';
import 'diplomacy_grant_aid_confirm_preview.dart';
import 'diplomacy_declare_war_third_party_preview.dart';
import 'diplomacy_resolver.dart';
import 'favored_trading_partner_preview.dart';

/// Short structured confirm body lines (Cost / Effect / When as applicable).
List<String> buildDiplomacyConfirmPreviewLines({
  required DiplomaticOrder order,
  required Game game,
  required String humanPlayerId,
  required String targetDisplayName,
}) {
  switch (order.type) {
    case DiplomaticOrderType.declareWar:
      return [
        ..._declareWar(targetDisplayName),
        ...declareWarThirdPartyPreviewLines(
          game: game,
          humanPlayerId: humanPlayerId,
          targetFactionId: order.targetFactionId,
        ),
      ];
    case DiplomaticOrderType.offerPeace:
      return _offerPeace(targetDisplayName);
    case DiplomaticOrderType.alliance:
      return _alliance(targetDisplayName);
    case DiplomaticOrderType.breakAlliance:
      return _breakAlliance(targetDisplayName);
    case DiplomaticOrderType.establishOverture:
      return _establishOverture(
        game: game,
        humanPlayerId: humanPlayerId,
        targetFactionId: order.targetFactionId,
        targetDisplayName: targetDisplayName,
        stage: order.overtureStage,
      );
    case DiplomaticOrderType.establishFtp:
      return _establishFtp(targetDisplayName);
    case DiplomaticOrderType.boycott:
      return boycottConfirmPreviewLines(
        game: game,
        humanPlayerId: humanPlayerId,
        targetDisplayName: targetDisplayName,
      );
    case DiplomaticOrderType.revokeBoycott:
      return revokeBoycottConfirmPreviewLines(
        game: game,
        humanPlayerId: humanPlayerId,
        targetDisplayName: targetDisplayName,
      );
    case DiplomaticOrderType.grantAid:
      return grantAidConfirmPreviewLines(
        game: game,
        humanPlayerId: humanPlayerId,
        targetFactionId: order.targetFactionId,
        targetDisplayName: targetDisplayName,
        amount: order.amount ?? grantAidDefaultAmount,
      );
    case DiplomaticOrderType.setSubsidy:
      return _setSubsidy(
        targetDisplayName,
        order.amount ?? kSubsidyPercentDefault,
      );
  }
}

String buildDiplomacyConfirmPreviewMessage({
  required DiplomaticOrder order,
  required Game game,
  required String humanPlayerId,
  required String targetDisplayName,
}) => buildDiplomacyConfirmPreviewLines(
  order: order,
  game: game,
  humanPlayerId: humanPlayerId,
  targetDisplayName: targetDisplayName,
).join('\n');

List<String> _declareWar(String target) => [
  'Effect: War with $target begins when this turn resolves. You may move and fight against them before then only where rules already allow.',
  'Effect: Ordinary overtures and embassies with $target end.',
];

List<String> _offerPeace(String target) => [
  'Effect: Offers peace to $target. Peace applies only if they accept.',
  'Effect: If accepted, you are at peace with $target; borders do not change.',
];

List<String> _alliance(String target) => [
  'Cost: No treasury charge.',
  'Effect: Offers a formal mutual-defence treaty with $target, distinct from merely friendly standing.',
  'Effect: If accepted, you are allied and may be called to their wars.',
];

List<String> _breakAlliance(String target) => [
  'When: The treaty ends immediately on confirm.',
  'Effect: Your standing with $target falls sharply.',
  'Effect: Other Great Powers take a lesser hit to standing with you.',
  'Effect: Until next turn, you cannot offer Alliance, an overture, '
      'Favored Trading Partner, Grant Aid, or Set Subsidy toward $target.',
  'Effect: Declare War and Offer Peace remain available this turn; '
      'the lock clears next turn.',
];

List<String> _establishFtp(String target) =>
    favoredTradingPartnerConfirmLines(target);

/// First-order buy/sell fill copy for a subsidy percent (Refs #4546).
/// Applies only to fills with [targetDisplayName]; not a per-turn gold charge.
String subsidyFillPriceConsequence({
  required String targetDisplayName,
  required int percent,
}) =>
    'On deals that fill with $targetDisplayName, you pay $percent% more when '
    'buying from them and receive $percent% less when selling to them.';

/// Compact-row Tooltip / semantics for active or pending subsidy (GAME30001).
String subsidyFillPriceConsequenceTooltip({
  required String targetDisplayName,
  required int percent,
}) =>
    '${subsidyFillPriceConsequence(targetDisplayName: targetDisplayName, percent: percent)} '
    'There is no per-turn gold charge.';

List<String> _setSubsidy(String target, int percent) => [
  'Cost: No per-turn gold charge.',
  'Effect: ${subsidyFillPriceConsequence(targetDisplayName: target, percent: percent)}',
];

List<String> _establishOverture({
  required Game game,
  required String humanPlayerId,
  required String targetFactionId,
  required String targetDisplayName,
  required OvertureStage? stage,
}) {
  final targetIsMinorOrTribe = isMinorOrTribe(game, targetFactionId);
  return switch (stage) {
    OvertureStage.tradeConsulate => [
      'Cost: £$overtureConsulateCost if $targetDisplayName accepts.',
      if (targetIsMinorOrTribe) ...[
        'Effect: If accepted, you may Explore and Prospect on '
            "$targetDisplayName's land.",
        'Effect: If accepted, your bids on $targetDisplayName\'s sales are '
            'served before courts with no Consulate (after First right of '
            'refusal).',
      ] else ...[
        'Effect: Offers a Trade Consulate; treasury is charged only on '
            'acceptance.',
      ],
      'Effect: You may later offer an Embassy.',
    ],
    OvertureStage.embassy => [
      'Cost: £$overtureEmbassyCost if $targetDisplayName accepts.',
      if (targetIsMinorOrTribe) ...[
        'Effect: If accepted, Grant Aid, Set Subsidy, and Purchase land '
            'become available toward $targetDisplayName.',
        'Effect: If accepted, when another Great Power declares war on '
            '$targetDisplayName, you may be asked to intervene.',
      ] else ...[
        'Effect: Offers an Embassy; treasury is charged only on acceptance.',
      ],
      'Effect: You may later offer a Non-Aggression Pact.',
    ],
    OvertureStage.nap => [
      'Cost: No treasury charge.',
      'Effect: If accepted, you may later offer Join Empire to '
          '$targetDisplayName.',
      'Effect: The pact does not by itself block Declare War.',
    ],
    OvertureStage.joinEmpire => _joinEmpire(
      game: game,
      targetFactionId: targetFactionId,
      targetDisplayName: targetDisplayName,
    ),
    OvertureStage.none || null => [
      'Effect: Offers the next overture stage with $targetDisplayName if they accept.',
    ],
  };
}

List<String> _joinEmpire({
  required Game game,
  required String targetFactionId,
  required String targetDisplayName,
}) {
  if (isGreatPower(game, targetFactionId)) {
    return [
      'Cost: No treasury charge.',
      'Effect: Offers Join Empire to the nearly defeated Great Power $targetDisplayName.',
      'Effect: If accepted, $targetDisplayName is absorbed and their provinces transfer to your realm.',
    ];
  }
  final cost = joinEmpireCostForMinorOrTribe(game, targetFactionId);
  final isTribe = game.tribes.any((t) => t.id == targetFactionId);
  if (isTribe) {
    return [
      'Cost: £$cost if $targetDisplayName accepts.',
      'Effect: Offers Join Empire to $targetDisplayName.',
      'Effect: If accepted, they become your colony.',
    ];
  }
  return [
    'Cost: £$cost if $targetDisplayName accepts.',
    'Effect: Offers Join Empire to $targetDisplayName.',
    'Effect: If accepted, their lands join your realm.',
  ];
}
