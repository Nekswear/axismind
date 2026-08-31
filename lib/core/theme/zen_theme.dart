import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

// =============================================================================
// AxisMind Design System — Premium Dark Theme
// =============================================================================
//
// Palette:
//   Background: #0A192F (deep navy)
//   Gold:       #C5A059 (noble gold)
//   Surface:    #0D2137 (elevated navy)
//   Text:       #E8E0D0 (warm light)
//
// Typography:
//   Display / Headings → PlayfairDisplay
//   Body / UI          → Manrope
// =============================================================================

// ---------------------------------------------------------------------------
// 1. TOKENS
// ---------------------------------------------------------------------------

/// Единый реестр дизайн-токенов AxisMind.
class ZenStyles extends ThemeExtension<ZenStyles> {
  // -- Скругления -----------------------------------------------------------
  final double cardRadius;

  // -- Типографика ----------------------------------------------------------
  final FontWeight metricWeight;

  // -- Сетка ----------------------------------------------------------------
  final double spacingUnit;

  // -- Градиенты ------------------------------------------------------------
  final LinearGradient focusGradient;
  final LinearGradient goldGradient;

  // -- Анимация -------------------------------------------------------------
  final Duration animationDuration;
  final Curve animationCurve;

  // -- Тени -----------------------------------------------------------------
  final List<double> elevationLevels;

  const ZenStyles({
    required this.cardRadius,
    required this.metricWeight,
    required this.spacingUnit,
    required this.focusGradient,
    required this.goldGradient,
    required this.animationDuration,
    required this.animationCurve,
    required this.elevationLevels,
  });

  /// Статический fallback.
  static const ZenStyles defaults = ZenStyles(
    cardRadius: 32.0,
    metricWeight: FontWeight.w700,
    spacingUnit: 8.0,
    focusGradient: LinearGradient(
      colors: [Color(0xFF0A192F), Color(0xFF0D2137)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    goldGradient: LinearGradient(
      colors: [Color(0xFFC5A059), Color(0xFFD4AF37), Color(0xFFC5A059)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [0.0, 0.5, 1.0],
    ),
    animationDuration: Duration(milliseconds: 300),
    animationCurve: Curves.easeInOut,
    elevationLevels: [0, 1, 2, 4, 8],
  );

  // -- Вспомогательные геттеры ----------------------------------------------

  EdgeInsets padding({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: spacingUnit * horizontal,
      vertical: spacingUnit * vertical,
    );
  }

  double gap(double multiplier) => spacingUnit * multiplier;

  @override
  ZenStyles copyWith({
    double? cardRadius,
    FontWeight? metricWeight,
    double? spacingUnit,
    LinearGradient? focusGradient,
    LinearGradient? goldGradient,
    Duration? animationDuration,
    Curve? animationCurve,
    List<double>? elevationLevels,
  }) {
    return ZenStyles(
      cardRadius: cardRadius ?? this.cardRadius,
      metricWeight: metricWeight ?? this.metricWeight,
      spacingUnit: spacingUnit ?? this.spacingUnit,
      focusGradient: focusGradient ?? this.focusGradient,
      goldGradient: goldGradient ?? this.goldGradient,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      elevationLevels: elevationLevels ?? this.elevationLevels,
    );
  }

  @override
  ZenStyles lerp(ThemeExtension<ZenStyles>? other, double t) {
    if (other is! ZenStyles) return this;
    return ZenStyles(
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t) ?? cardRadius,
      metricWeight:
          FontWeight.lerp(metricWeight, other.metricWeight, t) ?? metricWeight,
      spacingUnit:
          lerpDouble(spacingUnit, other.spacingUnit, t) ?? spacingUnit,
      focusGradient: focusGradient,
      goldGradient: goldGradient,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      elevationLevels: elevationLevels,
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Цветовые константы
// ---------------------------------------------------------------------------

class ZenColors {
  ZenColors._();

  static const Color background = Color(0xFF0A192F);
  static const Color surface = Color(0xFF0D2137);
  static const Color gold = Color(0xFFC5A059);
  static const Color goldLight = Color(0xFFD4AF37);
  static const Color textPrimary = Color(0xFFE8E0D0);
  static const Color textSecondary = Color(0xFFA09880);
  static const Color textMuted = Color(0xFF605848);
  static const Color border = Color(0x26C5A059); // gold at 0.15
}

// ---------------------------------------------------------------------------
// 3. ТЕМА
// ---------------------------------------------------------------------------

/// Фабрика полной тёмной темы AxisMind (Material 3 + ZenStyles).
class ZenTheme {
  ZenTheme._();

  /// Строит [ThemeData] с тёмной премиум-палитрой.
  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ZenColors.background,
      colorScheme: const ColorScheme.dark(
        primary: ZenColors.gold,
        surface: ZenColors.surface,
        onSurface: ZenColors.textPrimary,
        onPrimary: ZenColors.background,
      ),

      // -- TextTheme ---------------------------------------------------------
      textTheme: const TextTheme(
        // Таймер, главные цифры (PlayfairDisplay)
        displayLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 72,
          fontWeight: FontWeight.w200,
          letterSpacing: 4,
          color: ZenColors.textPrimary,
        ),
        // Крупный заголовок (PlayfairDisplay)
        headlineLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: ZenColors.textPrimary,
          letterSpacing: 1.2,
        ),
        // Приветствие / подзаголовок (PlayfairDisplay)
        headlineMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 22,
          fontWeight: FontWeight.normal,
          color: ZenColors.textPrimary,
        ),
        // Заголовки карточек (Manrope)
        titleMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: ZenColors.textPrimary,
        ),
        // Основной текст (Manrope)
        bodyLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: ZenColors.textPrimary,
        ),
        // Вторичные данные / подписи (Manrope)
        bodySmall: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ZenColors.textSecondary,
        ),
        // Кнопки (Manrope)
        labelLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ZenColors.textPrimary,
        ),
      ),

      // -- Кнопки -----------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ZenColors.gold,
          foregroundColor: ZenColors.background,
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      // -- AppBar ------------------------------------------------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ZenColors.textPrimary,
        elevation: 0,
      ),

      // -- Dialog ------------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: ZenColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),

      // -- Card --------------------------------------------------------------
      cardTheme: CardThemeData(
        color: ZenColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),

      // -- ZenStyles (кастомные токены) -------------------------------------
      extensions: const <ThemeExtension<dynamic>>[
        ZenStyles.defaults,
      ],
    );
  }
}
