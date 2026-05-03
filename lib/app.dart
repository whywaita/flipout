import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/game_controller.dart';
import 'screens/main_screen.dart';

class FlipoutApp extends StatelessWidget {
  const FlipoutApp({super.key, this.controller});

  final GameController? controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameController>(
      create: (_) {
        final provided = controller;
        if (provided != null) {
          return provided;
        }

        final created = GameController();
        unawaited(created.initialize());
        return created;
      },
      child: MaterialApp(
        title: 'Flip-Out',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F7B4D),
            primary: const Color(0xFF0F7B4D),
            secondary: const Color(0xFFB8872A),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F1E8),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
