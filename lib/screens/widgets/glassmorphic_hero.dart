import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../core/widgets/zen_ui.dart';
import '../../data/analytics_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/rank_localization.dart';
import 'gyro_controller.dart';
import 'mouse_tilt_controller.dart';
import 'rank_roadmap.dart';

/// 3D Glassmorphic Hero-карточка пользователя.
class GlassmorphicHero extends StatefulWidget {
  final UserProgression progression;
  final XpProgress xpProgress;
  final bool isCompact;
  final bool isDesktop;

  /// Пользователь авторизован через Google?
  final bool isAuthenticated;

  /// Колбэк для открытия экрана входа.
  final VoidCallback? onAuthTap;

  /// Колбэк для выхода из аккаунта.
  final VoidCallback? onSignOutTap;

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
    this.onSignOutTap,
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
        _tiltX = _mouseTilt!.transform[4] * 10;
        _tiltY = _mouseTilt!.transform[1] * 10;
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

    if (widget.isDesktop && _mouseTilt != null) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (event) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            _mouseTilt!.update(event.localPosition, box.size);
          }
        },
        child: _buildGlassCard(zen, theme),
      );
    }

    return _buildGlassCard(zen, theme);
  }

  Widget _buildGlassCard(ZenStyles zen, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(zen.cardRadius),
        border: Border.all(color: ZenColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(zen.cardRadius),
        child: _buildGlassLayer(zen, theme),
      ),
    );
  }

  Widget _buildGlassLayer(ZenStyles zen, ThemeData theme) {
    return Stack(
      fit: StackFit.loose,
      children: [
        // 1. Неинтерактивный размытый фон
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: ZenColors.surface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        // 2. Анимированный золотой градиент (только для Desktop)
        if (widget.isDesktop && _mouseTilt != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _mouseTilt!,
                builder: (context, _) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..translateByDouble(_tiltX * 30, _tiltY * 30, 0, 1),
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
                  );
                },
              ),
            ),
          )
        else
          Positioned.fill(
            child: IgnorePointer(
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
        // 3. Основное содержимое карточки
        _buildCardContent(context, theme, zen),
      ],
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    ThemeData theme,
    ZenStyles zen,
  ) {
    return Padding(
      padding: EdgeInsets.all(zen.spacingUnit * 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProfileRow(context, theme, zen),
          SizedBox(height: zen.gap(2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                      widget.progression.rank.title(
                        AppLocalizations.of(context)!,
                      ),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: ZenColors.textPrimary,
                        fontSize: widget.isCompact ? 18 : 22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.rankLevel(widget.progression.level.toString()),
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

  Widget _buildProfileRow(
    BuildContext context,
    ThemeData theme,
    ZenStyles zen,
  ) {
    if (widget.isAuthenticated) {
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
                child: const Icon(Icons.person, size: 18, color: ZenColors.gold),
              ),
            SizedBox(width: zen.spacingUnit),
            Text(
              widget.displayName ??
                  AppLocalizations.of(context)!.userPlaceholder,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ZenColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            if (widget.onSignOutTap != null)
              SizedBox(
                height: 30,
                child: TextButton.icon(
                  onPressed: widget.onSignOutTap,
                  icon: const Icon(
                    Icons.logout,
                    size: 14,
                    color: ZenColors.textMuted,
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.authSignOut,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ZenColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (widget.onAuthTap == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: zen.spacingUnit * 2),
      child: Center(
        child: SizedBox(
          width: 200,
          height: 38,
          child: OutlinedButton(
            onPressed: widget.onAuthTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: ZenColors.gold,
              side: BorderSide(color: ZenColors.gold.withValues(alpha: 0.5)),
              padding: EdgeInsets.zero,
              minimumSize: const Size(200, 38),
              fixedSize: const Size(200, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Icon(Icons.login, size: 16, color: ZenColors.gold),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.authGoogle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ZenColors.gold,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            tween: Tween<double>(begin: 0, end: widget.xpProgress.progress),
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
          AppLocalizations.of(
            context,
          )!.rankRemainingToNext(widget.xpProgress.remainingMinutes.toString()),
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
        Icon(Icons.local_fire_department, color: Colors.orange[300], size: 24),
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

  void _showRankRoadmap(BuildContext context) {
    RankRoadmap.show(
      context,
      currentLevel: widget.progression.level,
      totalMinutes: widget.progression.minutes,
    );
  }
}