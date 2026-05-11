import 'package:audioplayers/audioplayers.dart';

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
  Future<void> playStartGong() async {
    await _player.setVolume(_volume);
    await _player.play(AssetSource('audio/gong.mp3'));
  }

  /// Воспроизводит звук гонга при завершении медитации.
  Future<void> playEndGong() async {
    await _player.setVolume(_volume);
    await _player.play(AssetSource('audio/gong.mp3'));
  }

  /// Освобождает ресурсы аудиоплеера.
  void dispose() {
    _player.dispose();
  }
}
