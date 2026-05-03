import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/game_controller.dart';
import 'screens/main_screen.dart';

class FlipoutApp extends StatelessWidget {
  const FlipoutApp({super.key, this.controller});

  final GameController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff0f766e),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff101418),
      useMaterial3: true,
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: const Color(0xfff8fafc),
        displayColor: const Color(0xfff8fafc),
      ),
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
