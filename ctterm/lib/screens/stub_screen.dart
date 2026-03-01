// Generic stub screen: title + Esc to go back. SPEC/tui/ctterm.md.

import 'package:nocterm/nocterm.dart';

class StubScreen extends StatelessComponent {
  const StubScreen({super.key, required this.title});

  final String title;

  @override
  Component build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$title (stub)'),
          const SizedBox(height: 1),
          Text('Press Esc to go back', style: TextStyle(color: Colors.gray)),
        ],
      ),
    );
  }
}
