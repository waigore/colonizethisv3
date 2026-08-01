/// Plain-language copy for turn-event feed rows (Refs #4145).
class CtEventFeedText {
  CtEventFeedText._();

  static const Map<String, String> orderRejectedReasonLabels = {
    'insufficient_treasury': 'insufficient treasury',
    'invalid_destination': 'invalid destination',
    'insufficient_resources': 'insufficient resources',
    'insufficient_materials': 'insufficient materials',
    'invalid_order': 'invalid order',
  };

  static String orderRejectedReasonLabel(String reasonCode) {
    final mapped = orderRejectedReasonLabels[reasonCode];
    if (mapped != null) {
      return mapped;
    }
    if (reasonCode.contains(' ')) {
      return reasonCode;
    }
    return reasonCode.replaceAll('_', ' ');
  }

  static String orderRejectedLine(String reasonCode) =>
      'Order rejected: ${orderRejectedReasonLabel(reasonCode)}.';

  static String overseasProfitCreditedLine(int amount, int count) =>
      'Overseas profit credited: £$amount from $count rival purchase(s). '
      'Tap to open Deal Book.';
}
