import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../core/widgets/zen_ui.dart';
import '../../data/analytics_repository.dart';
import '../../l10n/app_localizations.dart';
import 'gyro_controller.dart';
import 'mouse_tilt_controller.dart';
import 'rank_roadmap.dart';

/// 3D Glassmorphic Hero-карточка пользователя.
///
/// **Мобильная версия:** Использует гироскоп ([GyroController]) для
/// параллакс-эффекта с low-pass фильтром.
///
/// **Desktop/Web версия:** Использует [MouseTiltController] для
/// эффекта «Магнитного Тилта» при движении курсора.
///
/// Многослойный `Stack`:
/// 1. Frosted Glass (BackdropFilter + blur) — только на desktop/web
/// 2. Золотое свечение (параллакс)
/// 3. Контент (ранг, XP, streak) — контр-параллакс
///
/// **Важно:** На Android `BackdropFilter` с `ImageFilter.blur` вызывает
/// сбой рендеринга на многих устройствах, поэтому используется fallback
/// с простым полупрозрачным фоном.
class GlassmorphicHero extends StatefulWidget {
  final UserProgression progression;
  final XpProgress xpProgress;
  final bool isCompact;
  final bool isDesktop;

  /// Пользователь авторизован через Google?
  final bool isAuthenticated;

  /// Колбэк для открытия экрана входа.
  /// Если null — кнопка входа не показывается.
  final VoidCallback? onAuthTap;

  /// Отображаемое имя пользователя (если авторизован).
  final String? displayName;

  /// URL аватара пользователя (если авторизован).
  final String? photoUrl;

  const GlassmorphicHero({
    super.key,
    required this.progression,
    required this.xpProgress,
    required this.isCompact,
    this.isDesktop = false,
    this.isAuthenticated = false,
    this.onAuthTap,
    this.displayName,
    this.photoUrl,
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

    final cardContent = _buildCardContent(context, theme, zen);

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
    // Desktop: используем AnimatedBuilder с MouseTiltController для плавных переходов
    if (_mouseTilt != null) {
      return AnimatedBuilder(
        animation: _mouseTilt!,
        builder: (context, child) {
          return _buildGlassCardContent(zen, child!);
        },
        child: content,
      );
    }

    // Мобильная версия: setState из GyroController перестраивает виджет
    return _buildGlassCardContent(zen, content);
  }

  /// Строит содержимое стеклянной карточки с параллакс-трансформациями.
  ///
  /// **Важно:** Не используем `Stack` с перекрывающимися детьми — на некоторых
  /// Android-устройствах это вызывает сбой рендеринга (синий экран с жёлтым овалом).
  /// Вместо этого используем один `Container` с `BoxDecoration` для фона и градиента,
  /// а контент размещаем поверх через `ClipRRect`.
  Widget _buildGlassCardContent(ZenStyles zen, Widget content) {
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
          child: _buildGlassLayer(zen, content),
        ),
      ),
    );
  }

  /// Строит слой стекла: [BackdropFilter] на desktop/web,
  /// простой полупрозрачный фон на Android.
  ///
  /// На Android также добавляет золотой градиент и контр-параллакс контента
  /// через `BoxDecoration` и `padding` соответственно.
  Widget _buildGlassLayer(ZenStyles zen, Widget content) {
    if (widget.isDesktop) {
      // Desktop/Web: полноценный эффект матового стекла через Stack
      // (на desktop проблем с рендерингом нет)
      return Stack(
        children: [
          // BackdropFilter
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: ZenColors.surface.withValues(alpha: 0.4),
              ),
            ),
          ),
          // Золотой градиент
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
          // Контент
          Positioned.fill(
            child: Transform(
              transform: Matrix4.identity()
                ..translateByDouble(
                  -_tiltX * 8,
                  -_tiltY * 8,
                  0,
                  1,
                ),
              child: content,
            ),
          ),
        ],
      );
    }

    // Android: единый Container с BoxDecoration (без Stack)
    return Container(
      decoration: BoxDecoration(
        color: ZenColors.surface.withValues(alpha: 0.5),
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
        borderRadius: BorderRadius.circular(zen.cardRadius),
      ),
      child: Transform(
        transform: Matrix4.identity()
          ..translateByDouble(
            -_tiltX * 8,
            -_tiltY * 8,
            0,
            1,
          ),
        child: content,
      ),
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

  Widget _buildCardContent(BuildContext context, ThemeData theme, ZenStyles zen) {
    return Padding(
      padding: EdgeInsets.all(zen.spacingUnit * 3),
      child: Column(
        children: [
          _buildProfileRow(context, theme, zen),
          SizedBox(height: zen.gap(2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Кнопка Roadmap
              GestureDetector(
                onTap: () => _showRankRoadmap(context),
                child: Container(
                  width: widget.isCompact ? 36 : 48,
                  height: widget.isCompact ? 36 : 48,
                  decoration: BoxDecoration(
                    color: ZenColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ZenColors.gold.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.map_outlined,
                      color: ZenColors.gold,
                      size: widget.isCompact ? 18 : 22,
                    ),
                  ),
                ),
              ),
              SizedBox(width: zen.spacingUnit),
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
                      AppLocalizations.of(context)!.rankLevel(widget.progression.level.toString()),
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
            _buildXpBar(context, theme, zen),
            SizedBox(height: zen.gap(2)),
            _buildStreakRow(context, theme, zen),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context, ThemeData theme, ZenStyles zen) {
    if (widget.isAuthenticated) {
      // Авторизован: показываем аватар и имя
      return Padding(
        padding: EdgeInsets.only(bottom: zen.spacingUnit * 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.photoUrl != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.photoUrl!),
              )
            else
              CircleAvatar(
                radius: 16,
                backgroundColor: ZenColors.gold.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: ZenColors.gold,
                ),
              ),
            SizedBox(width: zen.spacingUnit),
            Text(
              widget.displayName ?? AppLocalizations.of(context)!.userPlaceholder,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ZenColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Не авторизован: показываем кнопку входа (если есть колбэк)
    if (widget.onAuthTap == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: zen.spacingUnit * 2),
      child: SizedBox(
        width: 200,
        height: 36,
        child: OutlinedButton.icon(
          onPressed: widget.onAuthTap,
          icon: const Icon(Icons.login, size: 16),
          label: Text(
            AppLocalizations.of(context)!.authGoogle,
            style: const TextStyle(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: ZenColors.gold,
            side: BorderSide(
              color: ZenColors.gold.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXpBar(BuildContext context, ThemeData theme, ZenStyles zen) {
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
          AppLocalizations.of(context)!.rankRemainingToNext(widget.xpProgress.remainingMinutes.toString()),
          style: theme.textTheme.bodySmall?.copyWith(
            color: ZenColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakRow(BuildContext context, ThemeData theme, ZenStyles zen) {
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
          '${widget.progression.streak} ${widget.progression.streak == 1 ? AppLocalizations.of(context)!.statsStreakUnit : AppLocalizations.of(context)!.statsStreakUnitPlural}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: ZenColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Показывает Roadmap рангов.
  void _showRankRoadmap(BuildContext context) {
    RankRoadmap.show(
      context,
      currentLevel: widget.progression.level,
      totalMinutes: widget.progression.minutes,
    );
  }
}
