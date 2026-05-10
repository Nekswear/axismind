import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

// =============================================================================
// ZenDesign System — Design Tokens & Theme Extension
// =============================================================================
//
// Содержит:
//   1. ZenStyles — ThemeExtension с кастомными токенами.
//   2. ZenTheme.build() — фабрика ThemeData (Material 3) с интегрированными
//      ZenStyles и полным TextTheme.
//   3. ZenStyles.defaults — статический fallback-экземпляр.
//
// Использование:
//   final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
//   final theme = ZenTheme.build();  // в MaterialApp.theme
// =============================================================================

// ---------------------------------------------------------------------------
// 1. TOKENS
// ---------------------------------------------------------------------------

/// Единый реестр дизайн-токенов ZenBalance.
///
/// Все визуальные константы — только здесь. Запрещены прямые
/// fontSize/fontWeight/Color(0xFF) в виджетах.
class ZenStyles extends ThemeExtension<ZenStyles> {
  // -- Скругления -----------------------------------------------------------
  final double cardRadius;

  // -- Типографика ----------------------------------------------------------
  final FontWeight metricWeight;

  // -- Сетка ----------------------------------------------------------------
  final double spacingUnit;

  // -- Градиенты ------------------------------------------------------------
  final LinearGradient focusGradient;

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
    required this.animationDuration,
    required this.animationCurve,
    required this.elevationLevels,
  });

  /// Статический fallback — используется, когда extension<ZenStyles>() == null.
  static const ZenStyles defaults = ZenStyles(
    cardRadius: 24.0,
    metricWeight: FontWeight.w900,
    spacingUnit: 8.0,
    focusGradient: LinearGradient(
      colors: [Color(0xFF1A237E), Color(0xFFB0BEC5)], // индиго → серый
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    animationDuration: Duration(milliseconds: 300),
    animationCurve: Curves.easeInOut,
    elevationLevels: [0, 1, 2, 4, 8],
  );

  // -- Вспомогательные геттеры ----------------------------------------------

  /// Удобный доступ к padding = spacingUnit * [multiplier].
  EdgeInsets padding({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: spacingUnit * horizontal,
      vertical: spacingUnit * vertical,
    );
  }

  /// Удобный доступ к gap = spacingUnit * [multiplier].
  double gap(double multiplier) => spacingUnit * multiplier;

  @override
  ZenStyles copyWith({
    double? cardRadius,
    FontWeight? metricWeight,
    double? spacingUnit,
    LinearGradient? focusGradient,
    Duration? animationDuration,
    Curve? animationCurve,
    List<double>? elevationLevels,
  }) {
    return ZenStyles(
      cardRadius: cardRadius ?? this.cardRadius,
      metricWeight: metricWeight ?? this.metricWeight,
      spacingUnit: spacingUnit ?? this.spacingUnit,
      focusGradient: focusGradient ?? this.focusGradient,
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
      metricWeight: FontWeight.lerp(metricWeight, other.metricWeight, t) ?? metricWeight,
      spacingUnit: lerpDouble(spacingUnit, other.spacingUnit, t) ?? spacingUnit,
      focusGradient: focusGradient, // градиенты не интерполируем
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      elevationLevels: elevationLevels,
    );
  }
}

// ---------------------------------------------------------------------------
// 2. ТЕМА
// ---------------------------------------------------------------------------

/// Фабрика полной темы ZenBalance (Material 3 + ZenStyles).
class ZenTheme {
  ZenTheme._();

  static const Color _primaryColor = Color(0xFF4A90D9);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF2D2D2D);

  /// Строит [ThemeData] с Material 3, кастомным TextTheme и ZenStyles.
  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _backgroundColor,
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        surface: _backgroundColor,
        onSurface: _textColor,
      ),

      // -- TextTheme ---------------------------------------------------------
      textTheme: const TextTheme(
        // Таймер, главные цифры
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: _textColor,
        ),
        // Заголовки карточек
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: _textColor,
        ),
        // Вторичные данные / подписи
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _textColor,
        ),
        // Крупный заголовок (ZenBalance)
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: _textColor,
          letterSpacing: 1.2,
        ),
        // Приветствие / подзаголовок
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.normal,
          color: _textColor,
        ),
        // Основной текст
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: _textColor,
        ),
        // Кнопки
        labelLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),

      // -- Кнопки -----------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
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

      // -- ZenStyles (кастомные токены) -------------------------------------
      extensions: const <ThemeExtension<dynamic>>[
        ZenStyles.defaults,
      ],
    );
  }
}
