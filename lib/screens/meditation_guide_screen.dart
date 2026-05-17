// =============================================================================
// MeditationGuideScreen — экран-гид по медитации (дизайн из HTML/CSS)
// =============================================================================
//
// Содержит 5 секций:
//   1. Hero (тёмная) — ZenBalance, подзаголовок, плашка FINAL EDITION 2026
//   2. Сусокукан (светлая) — интерактивный счётчик дыхания
//   3. Геометрия Дзадзен (светлая) — три карточки
//   4. Преодоление сопротивления (светлая) — таблица 3×3
//   5. Финальная секция (тёмная) — цитата, кнопки, футер
//
// Навигация: MaterialPageRoute, без AppBar, свайп назад через PopScope,
//            кнопка закрытия Icons.close в правом верхнем углу.
//
// ВАЖНО: Внутри SingleChildScrollView НЕ ИСПОЛЬЗУЕТСЯ LayoutBuilder,
//        так как он получает maxHeight=infinity и вызывает зависание
//        в комбинации с Expanded/Row. Вместо этого используется
//        MediaQuery.of(context).size.width для адаптивности.
// =============================================================================

import 'package:flutter/material.dart';

import '../engine/breath_counter.dart';
import 'statistics_page.dart';

// =============================================================================
// 1. ДИЗАЙН-ТОКЕНЫ ЭКРАНА (изолированная палитра)
// =============================================================================

/// Цветовые константы для MeditationGuideScreen.
/// Не переопределяют глобальную тему ZenTheme.
class _GuideColors {
  static const Color navy = Color(0xFF0A192F);
  static const Color gold = Color(0xFFC5A059);
  static const Color cream = Color(0xFFFDFBF7);

  // Производные
  static const Color goldLight = Color(0x14C5A059); // gold с 8% opacity
  static const Color navyDivider = Color(0x1A0A192F); // navy с 10% opacity

  // Цвета таблицы диагностики
  static const Color problemBg = Color(0xFFFEE2E2);
  static const Color problemText = Color(0xFF991B1B);
  static const Color logicBg = Color(0xFFDBEAFE);
  static const Color logicText = Color(0xFF1E40AF);
  static const Color actionBg = Color(0xFFD1FAE5);
  static const Color actionText = Color(0xFF065F46);
}

// =============================================================================
// 2. ЭКРАН
// =============================================================================

class MeditationGuideScreen extends StatefulWidget {
  const MeditationGuideScreen({super.key});

  @override
  State<MeditationGuideScreen> createState() => _MeditationGuideScreenState();
}

class _MeditationGuideScreenState extends State<MeditationGuideScreen> {
  /// Счётчик дыхания Сусокукан.
  final BreathCounter _breathCounter = BreathCounter();

  @override
  void dispose() {
    _breathCounter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: _GuideColors.navy,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                // Максимальная ширина контента — 600px, центрирование
                width: MediaQuery.of(context).size.width > 600 ? 600.0 : MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    _buildHeroSection(context, isLandscape),
                    _buildSusokukanSection(context, isLandscape),
                    _buildZazenGeometrySection(context, isLandscape),
                    _buildResistanceTableSection(context, isLandscape),
                    _buildFinalSection(context, isLandscape),

                    // Кнопка закрытия (внизу)
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2.1 Hero-секция (тёмная)
  // ===========================================================================

  Widget _buildHeroSection(BuildContext context, [bool isLandscape = false]) {
    return _DarkSection(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 20 : 40,
          vertical: isLandscape ? 40 : 80,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Лейбл
            const _Label(text: 'Alex Merch Foundation'),
            SizedBox(height: isLandscape ? 12 : 20),

            // Заголовок ZenBalance
            Text(
              'ZenBalance',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.w900,
                fontSize: MediaQuery.of(context).size.width > 600 ? 80 : (isLandscape ? 40 : 60),
                letterSpacing: -2,
                height: 1.0,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLandscape ? 16 : 30),

            // Подзаголовок
            Text(
              'Рациональный путь к ясности ума',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w300,
                fontSize: isLandscape ? 18 : 24,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLandscape ? 30 : 60),

            // Плашка FINAL EDITION 2026
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _GuideColors.gold),
              ),
              child: const Text(
                'FINAL EDITION 2026',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 5,
                  color: _GuideColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2.2 Секция Сусокукан (светлая)
  // ===========================================================================

  Widget _buildSusokukanSection(BuildContext context, [bool isLandscape = false]) {
    return _LightSection(
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 20 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Лейбл
            const _Label(text: 'Техника: Сусокукан (Счёт дыхания)', color: _GuideColors.gold),
            const SizedBox(height: 20),

            // Заголовок
            Text(
              'Арифметика осознанности',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.w900,
                fontSize: isLandscape ? 28 : 36,
                color: _GuideColors.navy,
              ),
            ),
            const SizedBox(height: 8),

            // Разделительная линия
            Container(height: 1, color: _GuideColors.navyDivider),
            SizedBox(height: isLandscape ? 20 : 40),

            // Шаг 1: Посадка
            _buildInstructionStep(
              icon: Icons.airline_seat_legroom_normal,
              title: 'ПОСАДКА',
              description:
                  'Сядьте на край стула или в дзадзен. Спина прямая, но без напряжения. '
                  'Плечи расслаблены, руки в мудре (овальный замок).',
            ),
            const SizedBox(height: 20),

            // Шаг 2: Взгляд
            _buildInstructionStep(
              icon: Icons.remove_red_eye_outlined,
              title: 'ВЗГЛЯД',
              description:
                  'Глаза приоткрыты, взгляд направлен вниз под углом ~45° '
                  'на пол перед собой (1–1.5 метра). Не закрывайте глаза — '
                  'это уводит в сонливость и грёзы.',
            ),
            const SizedBox(height: 20),

            // Шаг 3: Фокус
            _buildInstructionStep(
              icon: Icons.blur_on_outlined,
              title: 'ФОКУС',
              description:
                  'Размойте зрение — не всматривайтесь в текстуру пола, '
                  'не фиксируйтесь на точках. Используйте периферическое зрение. '
                  'Вы смотрите, но не видите деталей.',
            ),
            const SizedBox(height: 24),

            // Шаг 4: Алгоритм
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _GuideColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat, color: _GuideColors.gold, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Считайте каждый выдох. Дойдя до 10, начните обратный отсчёт до 1. '
                      'Если мысль прервала счёт — вернитесь к единице.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isLandscape ? 20 : 40),

            // Интерактивный ряд цифр
            _buildBreathCounter(context),
            SizedBox(height: isLandscape ? 20 : 40),

            // Два блока: Биологический эффект и Правило Дзен — Wrap вместо Row
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildBioEffectCard(),
                _buildZenRuleCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Интерактивный ряд цифр 1–10 с анимацией активной цифры.
  Widget _buildBreathCounter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _GuideColors.goldLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Ряд цифр
          ValueListenableBuilder<int>(
            valueListenable: _breathCounter,
            builder: (context, currentValue, _) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: List.generate(10, (index) {
                  final number = index + 1;
                  final isActive = number == currentValue;
                  return AnimatedScale(
                    scale: isActive ? 1.4 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: isActive ? 1.0 : 0.2,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isActive ? _GuideColors.gold : _GuideColors.navy,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 24),

          // Кнопки управления
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterButton(
                label: 'ВЫДОХ',
                onPressed: () => _breathCounter.exhale(),
              ),
              const SizedBox(width: 16),
              _CounterButton(
                label: 'СБРОС',
                onPressed: () => _breathCounter.reset(),
                isOutlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Строит шаг инструкции с иконкой, заголовком и описанием.
  Widget _buildInstructionStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _GuideColors.goldLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: _GuideColors.gold),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 2,
                  color: _GuideColors.gold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  height: 1.5,
                  color: _GuideColors.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Карточка "Биологический эффект"
  Widget _buildBioEffectCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _GuideColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Биологический эффект',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: _GuideColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Счёт задействует префронтальную кору, блокируя «дефолт-систему» мозга, отвечающую за блуждание мыслей и тревогу.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка "Правило Дзен"
  Widget _buildZenRuleCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Правило Дзен',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: _GuideColors.navy,
                ),
              ),
              Icon(
                Icons.format_quote,
                size: 40,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '«Если вы потеряли счёт на цифре 9 — вы проиграли битву за внимание. Смиренно вернитесь к 1. Это и есть практика.»',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2.3 Секция Геометрия Дзадзен (светлая)
  // ===========================================================================

  Widget _buildZazenGeometrySection(BuildContext context, [bool isLandscape = false]) {
    return _LightSection(
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 20 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label(text: 'Форма и Содержание', color: _GuideColors.gold),
            const SizedBox(height: 20),

            Text(
              'Геометрия Дзадзен',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.w900,
                fontSize: isLandscape ? 28 : 36,
                color: _GuideColors.navy,
              ),
            ),
            SizedBox(height: isLandscape ? 20 : 40),

            // Три карточки — Wrap вместо Row, чтобы избежать Expanded внутри SingleChildScrollView
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildZazenCard(
                  title: 'Вертикаль',
                  description: 'Спина прямая, как струна. Это физиологическая база для бодрствующего сознания.',
                  borderColor: _GuideColors.gold,
                ),
                _buildZazenCard(
                  title: 'Взгляд',
                  description: 'Глаза приоткрыты, взгляд под 45° вниз, фокус размыт. Вы не уходите в мир грёз, вы остаётесь здесь и сейчас.',
                  borderColor: _GuideColors.navy,
                ),
                _buildZazenCard(
                  title: 'Мудра',
                  description: 'Руки в овальном замке. Это ваш физический датчик глубины концентрации.',
                  borderColor: _GuideColors.gold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZazenCard({
    required String title,
    required String description,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border(bottom: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: _GuideColors.navy,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              height: 1.5,
              color: _GuideColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2.4 Секция Преодоление сопротивления (светлая) — таблица
  // ===========================================================================

  Widget _buildResistanceTableSection(BuildContext context, [bool isLandscape = false]) {
    return _LightSection(
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 20 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label(text: 'Практическое руководство', color: _GuideColors.gold),
            const SizedBox(height: 20),

            Text(
              'Преодоление сопротивления',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.w900,
                fontSize: isLandscape ? 28 : 36,
                color: _GuideColors.navy,
              ),
            ),
            SizedBox(height: isLandscape ? 20 : 40),

            // Таблица
            _buildDiagnosticTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticTable(BuildContext context) {
    // Данные таблицы
    const rows = <_TableRowData>[
      _TableRowData(
        problem: 'Зуд и беспокойство',
        logic: 'Защитная реакция эго на непривычную тишину.',
        action: 'Мусётоку. Наблюдай зуд как посторонний объект. Он уйдет сам.',
      ),
      _TableRowData(
        problem: 'Ментальный шум',
        logic: 'Попытка мозга заполнить вакуум привычными планами.',
        action: 'Сусокукан. Мягко верни внимание к счёту «Один». Без агрессии.',
      ),
      _TableRowData(
        problem: 'Сонливость',
        logic: 'Признак потери тонуса и соскальзывания в транс.',
        action: 'Энергия. Выпрями спину. Приоткрой глаза. Дыши чуть глубже.',
      ),
    ];

    // Всегда используем мобильную версию (карточки), чтобы избежать Row + Expanded внутри SingleChildScrollView
    return Column(
      children: rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tableHeaderSmall('Проблема'),
              const SizedBox(height: 4),
              _tableCellSmall(row.problem, _GuideColors.problemBg, _GuideColors.problemText),
              const SizedBox(height: 12),
              _tableHeaderSmall('Механизм ума'),
              const SizedBox(height: 4),
              _tableCellSmall(row.logic, _GuideColors.logicBg, _GuideColors.logicText),
              const SizedBox(height: 12),
              _tableHeaderSmall('Дзен-решение'),
              const SizedBox(height: 4),
              _tableCellSmall(row.action, _GuideColors.actionBg, _GuideColors.actionText),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _tableHeaderSmall(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 2,
        color: _GuideColors.gold,
      ),
    );
  }

  Widget _tableCellSmall(String text, Color bg, Color fg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: fg,
        ),
      ),
    );
  }

  // ===========================================================================
  // 2.5 Финальная секция (тёмная)
  // ===========================================================================

  Widget _buildFinalSection(BuildContext context, [bool isLandscape = false]) {
    return _DarkSection(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 20 : 40,
          vertical: isLandscape ? 40 : 80,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Заголовок
            Text(
              'Будьте Свидетелем.',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.w900,
                fontSize: isLandscape ? 32 : (MediaQuery.of(context).size.width > 600 ? 64 : 48),
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLandscape ? 12 : 20),

            // Цитата
            Text(
              'Ваш ум — ваш главный актив.',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontStyle: FontStyle.italic,
                fontSize: isLandscape ? 22 : 28,
                color: _GuideColors.gold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLandscape ? 30 : 60),

            // Кнопки
            Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildFinalButton(
                  label: 'УЗНАТЬ БОЛЬШЕ',
                  isOutlined: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StatisticsPage(),
                      ),
                    );
                  },
                ),
                _buildFinalButton(
                  label: 'НАЧАТЬ ПРАКТИКУ',
                  isOutlined: false,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 30 : 60),

            // Футер
            Text(
              'ALEX MERCH • ZENBALANCE SYSTEM • 2026',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                letterSpacing: 4,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalButton({
    required String label,
    required bool isOutlined,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: _GuideColors.gold,
                side: const BorderSide(color: _GuideColors.gold),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                shape: const BeveledRectangleBorder(),
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              child: Text(label),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _GuideColors.gold,
                foregroundColor: _GuideColors.navy,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                shape: const BeveledRectangleBorder(),
                elevation: 0,
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              child: Text(label),
            ),
    );
  }
}

// =============================================================================
// 3. ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
// =============================================================================

/// Тёмная секция с золотой линией сверху.
class _DarkSection extends StatelessWidget {
  final Widget child;

  const _DarkSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _GuideColors.navy,
      child: Column(
        children: [
          // Золотая линия сверху
          Container(
            height: 8,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_GuideColors.navy, _GuideColors.gold],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Светлая секция.
class _LightSection extends StatelessWidget {
  final Widget child;

  const _LightSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _GuideColors.cream,
      child: child,
    );
  }
}

/// Лейбл (акцентный текст).
class _Label extends StatelessWidget {
  final String text;
  final Color color;

  const _Label({
    required this.text,
    this.color = _GuideColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 6,
        color: color,
      ),
    );
  }
}

/// Кнопка управления счётчиком.
class _CounterButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;

  const _CounterButton({
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: _GuideColors.gold,
                side: const BorderSide(color: _GuideColors.gold),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              child: Text(label),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _GuideColors.gold,
                foregroundColor: _GuideColors.navy,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                elevation: 0,
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              child: Text(label),
            ),
    );
  }
}

/// Внутренняя модель строки таблицы.
class _TableRowData {
  final String problem;
  final String logic;
  final String action;

  const _TableRowData({
    required this.problem,
    required this.logic,
    required this.action,
  });
}
