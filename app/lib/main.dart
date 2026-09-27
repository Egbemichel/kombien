import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'theme/kombien_theme.dart';

void main() {
  runApp(const KombienApp());
}

class KombienApp extends StatelessWidget {
  const KombienApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kombien',
      debugShowCheckedModeBanner: false,
      theme: KombienTheme.light,
      darkTheme: KombienTheme.dark,
      themeMode: ThemeMode.system,
      home: const RootShell(),
    );
  }
}
