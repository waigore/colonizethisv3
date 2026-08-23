// Work-tile overlay hosts for pick-first-valid-tile pins (#4598 Slice B).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart'
    show kCtE2ESelectFirstValidWorkTileKey;
import 'package:flutter/material.dart';

class WorkTileOverlayHost extends StatefulWidget {
  const WorkTileOverlayHost({super.key});

  @override
  State<WorkTileOverlayHost> createState() => WorkTileOverlayHostState();
}

class WorkTileOverlayHostState extends State<WorkTileOverlayHost> {
  bool _visible = true;
  int taps = 0;

  void _onTap() {
    taps++;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: !_visible
              ? const SizedBox.shrink(key: ValueKey('overlay-cleared'))
              : SizedBox(
                  width: 64,
                  height: 64,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: kCtE2ESelectFirstValidWorkTileKey,
                      onTap: _onTap,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class EmptyWorkTileHost extends StatelessWidget {
  const EmptyWorkTileHost({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: Scaffold(body: SizedBox.shrink()));
}
