import 'progress_calculator.dart';

/// Событие повышения уровня пользователя.
///
/// Содержит данные о новом уровне и ранге после завершения сессии.
class LevelUpEvent {
  /// Новый уровень.
  final int level;

  /// Новый ранг (enum — локализуется в UI-слое).
  final Rank rank;

  const LevelUpEvent({required this.level, required this.rank});
}
