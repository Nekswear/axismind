import 'package:flutter/material.dart';

/// Анимированный шиммер-скелетон для состояния загрузки.
///
/// Показывает 3 прямоугольника с градиентной анимацией,
/// имитирующих структуру будущего контента:
///   - XP-Bar (узкий)
///   - Карточки summary (две рядом)
///   - Блок графика (высокий)
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final highlightColor = theme.colorScheme.onSurface.withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // XP-Bar скелетон
              _ShimmerBlock(
                width: double.infinity,
                height: 60,
                baseColor: baseColor,
                highlightColor: highlightColor,
                animation: _animation,
              ),

              const SizedBox(height: 24),

              // Две карточки summary
              Row(
                children: [
                  Expanded(
                    child: _ShimmerBlock(
                      width: double.infinity,
                      height: 100,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      animation: _animation,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShimmerBlock(
                      width: double.infinity,
                      height: 100,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      animation: _animation,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Заголовок heatmap
              _ShimmerBlock(
                width: 180,
                height: 20,
                baseColor: baseColor,
                highlightColor: highlightColor,
                animation: _animation,
              ),

              const SizedBox(height: 12),

              // Сетка heatmap (5 строк по 7 ячеек)
              ...List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    ...List.generate(7, (_) => Expanded(
                      child: Center(
                        child: _ShimmerBlock(
                          width: 14,
                          height: 14,
                          borderRadius: 3,
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                          animation: _animation,
                        ),
                      ),
                    )),
                  ],
                ),
              )),

              const SizedBox(height: 24),

              // Заголовок графика
              _ShimmerBlock(
                width: 140,
                height: 20,
                baseColor: baseColor,
                highlightColor: highlightColor,
                animation: _animation,
              ),

              const SizedBox(height: 16),

              // График
              _ShimmerBlock(
                width: double.infinity,
                height: 220,
                baseColor: baseColor,
                highlightColor: highlightColor,
                animation: _animation,
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

/// Один блок-скелетон с анимированным шиммер-эффектом.
class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final Animation<double> animation;

  const _ShimmerBlock({
    required this.width,
    required this.height,
    this.borderRadius = 12,
    required this.baseColor,
    required this.highlightColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientSlide(animation.value),
        ),
      ),
    );
  }
}

/// Трансформация градиента для создания эффекта движения.
class GradientSlide extends GradientTransform {
  final double offset;

  const GradientSlide(this.offset);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * offset, 0, 0);
  }
}
