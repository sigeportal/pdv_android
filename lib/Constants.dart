import 'package:flutter/material.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';

class Constants {
  static String normalizeHex(String value, {String fallback = 'FFBF00'}) {
    final cleaned = value.trim().replaceAll('#', '').toUpperCase();
    if (cleaned.isEmpty) return fallback;
    return cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned;
  }

  static Color colorFromHex(String value, {String fallback = 'FFBF00'}) {
    final normalized = normalizeHex(value, fallback: fallback);
    final argb = 'FF$normalized';
    final parsed = int.tryParse(argb, radix: 16);
    if (parsed == null) {
      final fallbackValue = int.parse('FF$fallback', radix: 16);
      return Color(fallbackValue);
    }
    return Color(parsed);
  }

  static Color shade(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0).toDouble();
    return hsl.withLightness(lightness).toColor();
  }

  static Color get primaryColor =>
      colorFromHex(ConfigController.instance.primaryColorHex.value,
          fallback: 'FFBF00');

  static Color get secondaryColor =>
      colorFromHex(ConfigController.instance.secondaryColorHex.value,
          fallback: '2E8B57');

  static Color get secondaryColorDark => shade(secondaryColor, -0.15);

  static Color get secondaryColorLight => shade(secondaryColor, 0.12);

  static final Color mesaOcupada = Color.fromRGBO(73, 115, 255, 1);
  static final Color mesaAberta = Color.fromRGBO(28, 184, 109, 1);
  static final Color mesaFechamento = Color.fromRGBO(253, 121, 118, 1);
}
