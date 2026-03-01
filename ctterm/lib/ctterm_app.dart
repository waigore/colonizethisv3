// Root ctterm app: navigation shell and main menu. SPEC/tui/ctterm.md.

import 'package:nocterm/nocterm.dart';

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/screens/shell_screen.dart';

/// Root component. Holds current screen and shows Main Menu or a stub.
class CttermApp extends StatefulComponent {
  const CttermApp({super.key, this.dataDirOverride});

  final String? dataDirOverride;

  @override
  State<CttermApp> createState() => _CttermAppState();
}

class _CttermAppState extends State<CttermApp> {
  CttermRoute _route = CttermRoute.mainMenu;

  void _navigateTo(CttermRoute route) {
    setState(() => _route = route);
  }

  void _exit() {
    shutdownApp(0);
  }

  @override
  Component build(BuildContext context) {
    return NoctermApp(
      title: 'ColonizeThis',
      child: ShellScreen(
        route: _route,
        dataDirOverride: component.dataDirOverride,
        onNavigate: _navigateTo,
        onExit: _exit,
      ),
    );
  }
}
