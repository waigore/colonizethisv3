import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic civilian-panel host whose body is provided by the test.
class CustomCivilianPanelHost extends StatefulWidget {
  const CustomCivilianPanelHost({
    required this.bodyBuilder,
    this.includeRootKey = true,
    this.showWorkMenuOnTap = true,
  });

  final Widget Function(VoidCallback onAssignTapped) bodyBuilder;
  final bool includeRootKey;
  final bool showWorkMenuOnTap;

  @override
  State<CustomCivilianPanelHost> createState() =>
      CustomCivilianPanelHostState();
}

class CustomCivilianPanelHostState extends State<CustomCivilianPanelHost> {
  bool tapped = false;

  void _markTapped() {
    if (!widget.showWorkMenuOnTap) {
      return;
    }
    setState(() {
      tapped = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.bodyBuilder(_markTapped);
    final rootChild = Column(
      children: <Widget>[
        Expanded(child: body),
        if (tapped) const Text('Build improvement'),
      ],
    );
    return MaterialApp(
      home: Scaffold(
        body: widget.includeRootKey
            ? Container(key: kCtE2ECivilianPanelRootKey, child: rootChild)
            : rootChild,
      ),
    );
  }
}

bool customCivilianPanelHostWasTapped(WidgetTester tester) {
  final stateFinder = find.byType(CustomCivilianPanelHost);
  if (stateFinder.evaluate().isEmpty) {
    return false;
  }
  final state = tester.state<CustomCivilianPanelHostState>(stateFinder);
  return state.tapped;
}
