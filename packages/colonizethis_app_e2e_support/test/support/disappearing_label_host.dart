// Shared hide-on-tap label host for `e2e_idle_poll_step_test.dart`
// (Refs #4598 leftover host SoT). Pin suites import this instead of declaring
// `_DisappearingLabel` locally.
library;

import 'package:flutter/material.dart';

/// Scaffold that shows [goneLabel] until the hide button is tapped.
class DisappearingLabelHost extends StatefulWidget {
  const DisappearingLabelHost({
    super.key,
    this.goneLabel = 'gone',
    this.hideLabel = 'hide',
  });

  final String goneLabel;
  final String hideLabel;

  @override
  State<DisappearingLabelHost> createState() => DisappearingLabelHostState();
}

class DisappearingLabelHostState extends State<DisappearingLabelHost> {
  bool showGone = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (showGone) Text(widget.goneLabel),
          TextButton(
            onPressed: () => setState(() => showGone = false),
            child: Text(widget.hideLabel),
          ),
        ],
      ),
    );
  }
}
