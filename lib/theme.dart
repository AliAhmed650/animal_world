import 'package:flutter/material.dart';

const Map<String, Color> kCatColor = {
  'pets': Color(0xFFEC4899),
  'farm': Color(0xFFF59E0B),
  'wild': Color(0xFFE4572E),
  'birds': Color(0xFF2BA3E0),
  'sea': Color(0xFF14B8A6),
  'bugs': Color(0xFF6DB33F),
};

ThemeData buildTheme(Brightness brightness) => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF14B8A6),
      brightness: brightness,
    );
