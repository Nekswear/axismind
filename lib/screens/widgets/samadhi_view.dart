import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/zen_theme.dart';

/// Бесконечная фаза интеграции «Самадхи».
///
/// После финального гонга переводит экран в полноэкранный режим.
///
/// **Выход:**
/// - Мобильные: одиночный тап в любое место экрана
/// - Desktop/Web: клик мыши или нажатие Space
///
/// При выходе плавно затухает (400ms), после чего вызывается [onExited].
class SamadhiView extends StatefulWidget {
  /// Колбэк при завершении анимации затухания.
  final VoidCallback onExited;

  /// Флаг: Desktop/Web режим (показывает KeyboardListener).
  final bool isDesktop;

  const SamadhiView({
    super.key,
    required this.onExited,
    this.isDesktop = false,
  });

  @override
  State<SamadhiView> createState() => _SamadhiViewState();
}

class _SamadhiViewState extends State<SamadhiView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeOutController;

  bool _isFadingOut = false;

  @override
  void initState() {
    super.initState();

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _fadeOutController.dispose();
    super.dispose();
  }

  void _handleExit() {
    if (_isFadingOut) return;
    setState(() => _isFadingOut = true);

    _fadeOutController.forward().then((_) {
      if (mounted) {
        widget.onExited();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget view = GestureDetector(
      onTap: _handleExit,
      child: AnimatedBuilder(
        animation: _fadeOutController,
        builder: (context, _) {
          final fadeOpacity =
              (1 - _fadeOutController.value).clamp(0.0, 1.0);

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: ZenColors.background,
            child: Stack(
              children: [
                // Desktop/Web: подсказка выхода
                if (widget.isDesktop)
                  Positioned(
                    bottom: 48,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: 0.4 * fadeOpacity,
                      child: Text(
                        'Нажмите Пробел или кликните для выхода',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: ZenColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    // Desktop/Web: KeyboardListener для выхода по Space
    if (widget.isDesktop) {
      view = KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.space) {
            _handleExit();
          }
        },
        child: view,
      );
    }

    return view;
  }
}
