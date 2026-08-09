import 'package:flutter/material.dart';

import 'ct_transfer_list.dart';
import 'ct_transfer_list_layout.dart';
import 'ct_transfer_list_mutations.dart';
import 'ct_transfer_list_state_base.dart';

/// Stateful implementation for [CtTransferList] (Refs #4117 de-part).
class CtTransferListState extends State<CtTransferList>
    with
        CtTransferListStateBase,
        CtTransferListMutations,
        CtTransferListLayout {
  @override
  Widget build(BuildContext context) => buildTransferListLayout(context);
}
