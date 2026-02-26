import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'config/themes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colonize This',
      theme: AppThemes.light,
      initialRoute: Routes.shell,
      onGenerateRoute: Routes.generate,
    );
  }
}
