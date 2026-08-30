// Shared modal-sheet host for `e2e_close_bottom_sheet_test.dart`
// (#4598 leftover host SoT).
library;

import 'package:flutter/material.dart';

/// Opens a [ModalBottomSheetRoute] after the first frame so close-helper
/// pins can assert pop-once-then-poll without a local StatefulWidget.
class CloseBottomSheetHost extends StatefulWidget {
  const CloseBottomSheetHost({super.key});

  @override
  State<CloseBottomSheetHost> createState() => _CloseBottomSheetHostState();
}

class _CloseBottomSheetHostState extends State<CloseBottomSheetHost> {
  bool _opened = false;

  void _open(BuildContext context) {
    if (_opened) return;
    _opened = true;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SizedBox(
        height: 200,
        child: Center(child: Text('panel-content')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (innerCtx) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _open(innerCtx));
          return const SizedBox.expand();
        },
      ),
    );
  }
}
