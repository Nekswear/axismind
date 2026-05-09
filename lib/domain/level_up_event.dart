/// Событие повышения уровня пользователя.
///
/// Содержит данные о новом уровне и ранге после завершения сессии.
class LevelUpEvent {
  /// Новый уровень.
  final int level;

  /// Название нового ранга.
  final String rank;

  const LevelUpEvent({required this.level, required this.rank});
}
