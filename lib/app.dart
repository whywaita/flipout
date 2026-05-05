import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/game_controller.dart';
import 'screens/main_screen.dart';
import 'theme/tokens.dart';

class FlipoutApp extends StatelessWidget {
  const FlipoutApp({super.key, this.controller});

  final GameController? controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: FlipoutColors.accent,
      primary: FlipoutColors.accent,
      onPrimary: Colors.white,
      surface: FlipoutColors.surface1,
      onSurface: FlipoutColors.text,
      brightness: Brightness.light,
    );

    final theme = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FlipoutColors.bg,
      useMaterial3: true,
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: FlipoutColors.text,
        displayColor: FlipoutColors.text,
      ),
      iconTheme: const IconThemeData(color: FlipoutColors.textMuted),
    );

    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flip-Out',
      theme: theme,
      home: const MainScreen(),
    );

    if (controller != null) {
      return ChangeNotifierProvider<GameController>.value(
        value: controller!,
        child: app,
      );
    }

    return ChangeNotifierProvider<GameController>(
      create: (_) {
        final gameController = GameController();
        gameController.loadSettings();
        return gameController;
      },
      child: app,
    );
  }
}
