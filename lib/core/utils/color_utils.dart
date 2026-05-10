import 'package:flutter/material.dart';

class ColorUtils {
  const ColorUtils._();

  static Color fromHex(String hex) {
    final normalized = hex.replaceAll('#', '');
    final value = normalized.length == 6 ? 'FF$normalized' : normalized;
    return Color(int.parse(value, radix: 16));
  }

  static String toHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }
}
