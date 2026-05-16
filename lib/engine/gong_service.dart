import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Сервис для воспроизведения звука гонга.
///
/// Используется в [TimerPage] для акустического сигнала
/// в начале и конце сессии медитации.
class GongService {
  final AudioPlayer _player = AudioPlayer();

  /// Громкость гонга (0.0 – 1.0).
  /// Умеренное значение, чтобы не нарушать медитативную атмосферу.
  static const double _volume = 0.5;

  /// Воспроизводит звук гонга при старте медитации.
  ///
  /// Ошибки воспроизведения (например, файл не найден) перехватываются
  /// и логируются, чтобы не прерывать медитацию.
  Future<void> playStartGong() async {
    try {
      await _player.setVolume(_volume);
      await _player.play(AssetSource('audio/gong.mp3'));
    } catch (e) {
      debugPrint('GongService: failed to play start gong: $e');
    }
  }

  /// Воспроизводит звук гонга при завершении медитации.
  ///
  /// Ошибки воспроизведения перехватываются и логируются.
  Future<void> playEndGong() async {
    try {
      await _player.setVolume(_volume);
      await _player.play(AssetSource('audio/gong.mp3'));
    } catch (e) {
      debugPrint('GongService: failed to play end gong: $e');
    }
  }

  /// Освобождает ресурсы аудиоплеера.
  void dispose() {
    _player.dispose();
  }
}
