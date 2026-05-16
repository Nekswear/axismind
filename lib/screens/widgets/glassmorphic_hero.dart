import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../core/widgets/zen_ui.dart';
import '../../data/analytics_repository.dart';
import 'gyro_controller.dart';
import 'mouse_tilt_controller.dart';

/// 3D Glassmorphic Hero-карточка пользователя.
///
/// **Мобильная версия:** Использует гироскоп ([GyroController]) для
/// параллакс-эффекта с low-pass фильтром.
///
/// **Desktop/Web версия:** Использует [MouseTiltController] для
/// эффекта «Магнитного Тилта» при движении курсора.
///
/// Многослойный `Stack`:
/// 1. Frosted Glass (BackdropFilter + blur)
/// 2. Золотое свечение (параллакс)
/// 3. Контент (ранг, XP, streak) — контр-параллакс
class GlassmorphicHero extends StatefulWidget {
  final UserProgression progression;
  final XpProgress xpProgress;
  final bool isCompact;
  final bool isDesktop;

  const GlassmorphicHero({
    super.key,
    required this.progression,
    required this.xpProgress,
    required this.isCompact,
    this.isDesktop = false,
  });

  @override
  State<GlassmorphicHero> createState() => _GlassmorphicHeroState();
}

class _GlassmorphicHeroState extends State<GlassmorphicHero>
    with SingleTickerProviderStateMixin {
  GyroController? _gyro;
  MouseTiltController? _mouseTilt;

  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();

    if (widget.isDesktop) {
      _mouseTilt = MouseTiltController();
      _mouseTilt!.addListener(_onTiltUpdate);
    } else if (!kIsWeb) {
      _gyro = GyroController();
      _gyro!.start((x, y) {
        if (mounted) {
          setState(() {
            _tiltX = x;
            _tiltY = y;
          });
        }
      });
    }
  }

  void _onTiltUpdate() {
    if (mounted && _mouseTilt != null) {
      setState(() {
        // Извлекаем углы наклона из матрицы для золотого блика
        _tiltX = _mouseTilt!.transform[4] * 10; // rotationY
        _tiltY = _mouseTilt!.transform[1] * 10; // rotationX
      });
    }
  }

  @override
  void dispose() {
    _gyro?.dispose();
    _mouseTilt?.removeListener(_onTiltUpdate);
    _mouseTilt?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final theme = Theme.of(context);

    final cardContent = _buildCardContent(theme, zen);

    // Desktop/Web: оборачиваем в MouseRegion
    if (widget.isDesktop && _mouseTilt != null) {
      return MouseRegion(
        onHover: (event) {
          final box = context.findRenderObject() as RenderBox;
          _mouseTilt!.update(event.localPosition, box.size);
        },
        onExit: (_) => _mouseTilt!.reset(),
        child: _buildGlassCard(zen, cardContent),
      );
    }

    return _buildGlassCard(zen, cardContent);
  }

  Widget _buildGlassCard(ZenStyles zen, Widget content) {
    return AnimatedBuilder(
      animation: Listenable.merge([?_mouseTilt]),
      builder: (context, child) {
        return Transform(
          transform: _buildTransform(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(zen.cardRadius),
              border: Border.all(
                color: ZenColors.border,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(zen.cardRadius),
              child: Stack(
                children: [
                  // Слой 1: Frosted Glass (BackdropFilter)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: ZenColors.surface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                  // Слой 2: Золотое свечение (параллакс)
                  Positioned.fill(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translateByDouble(
                          _tiltX * 30,
                          _tiltY * 30,
                          0,
                          1,
                        ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              ZenColors.gold.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                            radius: 1.2,
                            center: Alignment(
                              _tiltX.clamp(-0.5, 0.5),
                              _tiltY.clamp(-0.5, 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Слой 3: Контент (контр-параллакс)
                  Positioned.fill(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translateByDouble(
                          -_tiltX * 8,
                          -_tiltY * 8,
                          0,
                          1,
                        ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Matrix4 _buildTransform() {
    if (_mouseTilt != null) {
      return _mouseTilt!.transform;
    }
    // Мобильная версия: параллакс через Matrix4
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..translateByDouble(_tiltX * 15, _tiltY * 15, 0, 1);
  }

  Widget _buildCardContent(ThemeData theme, ZenStyles zen) {
    return Padding(
      padding: EdgeInsets.all(zen.spacingUnit * 3),
      child: Column(
        children: [
          _buildProfileRow(theme, zen),
          SizedBox(height: zen.gap(2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RankIcon(
                level: widget.progression.level,
                size: widget.isCompact ? 36 : 48,
              ),
              SizedBox(width: zen.spacingUnit * 2),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.progression.rank,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: ZenColors.textPrimary,
                        fontSize: widget.isCompact ? 18 : 22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Уровень ${widget.progression.level}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ZenColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!widget.isCompact) ...[
            SizedBox(height: zen.gap(3)),
            _buildXpBar(theme, zen),
            SizedBox(height: zen.gap(2)),
            _buildStreakRow(theme, zen),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileRow(ThemeData theme, ZenStyles zen) {
    // Заглушка — реальная логика профиля остаётся в home_screen.dart
    return const SizedBox.shrink();
  }

  Widget _buildXpBar(ThemeData theme, ZenStyles zen) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: widget.xpProgress.progress,
            ),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: ZenColors.textMuted.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  ZenColors.gold.withValues(alpha: 0.9),
                ),
              );
            },
          ),
        ),
        SizedBox(height: zen.spacingUnit),
        Text(
          'Осталось ${widget.xpProgress.remainingMinutes} мин до следующего уровня',
          style: theme.textTheme.bodySmall?.copyWith(
            color: ZenColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakRow(ThemeData theme, ZenStyles zen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.local_fire_department,
          color: Colors.orange[300],
          size: 24,
        ),
        SizedBox(width: zen.spacingUnit),
        Text(
          '${widget.progression.streak} дней подряд',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: ZenColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
