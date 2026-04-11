import 'package:flutter/material.dart';

ThemeData buildTheme() {
  return ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.orange,
    ),
  );
}
