import 'package:flutter/material.dart';

import 'package:sudoku_game/theme.dart';
import 'package:sudoku_game/screens/home_screen.dart';

void main() => runApp(const SudokuApp());

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gridline Sudoku',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      home: HomeScreen(),
    );
  }
}