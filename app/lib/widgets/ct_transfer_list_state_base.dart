import 'package:flutter/material.dart';

import 'ct_transfer_list.dart';

/// Shared count state for [CtTransferList] mixins (Refs #4117 de-part).
mixin CtTransferListStateBase on State<CtTransferList> {
  late Map<String, int> leftCounts;
  late Map<String, int> rightCounts;

  int get leftTotal => leftCounts.values.fold(0, (sum, count) => sum + count);
  int get rightTotal => rightCounts.values.fold(0, (sum, count) => sum + count);

  bool get canConfirm {
    final validate = widget.canConfirm;
    if (validate == null) {
      return rightTotal > 0;
    }
    return validate(leftCounts, rightCounts);
  }

  @override
  void initState() {
    super.initState();
    leftCounts = Map<String, int>.from(widget.initialLeftCounts);
    rightCounts = Map<String, int>.from(widget.initialRightCounts);
  }
}
