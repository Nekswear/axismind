import '../domain/progress_calculator.dart';
import 'app_localizations.dart';

// =============================================================================
// RankLocalization — локализованные названия и описания рангов
// =============================================================================
//
// Доменный слой хранит ранг как enum [Rank], а отображение на
// человекочитаемые строки выполняется здесь, в UI-слое, через
// [AppLocalizations]. Это позволяет полностью переводить названия
// уровней (геймификацию) на язык интерфейса.
// =============================================================================

/// Расширение [Rank] методами локализации.
extension RankLocalization on Rank {
  /// Локализованное название ранга (например, "Mindfulness Novice" / "Новичок осознанности").
  String title(AppLocalizations l10n) {
    switch (this) {
      case Rank.novice:
        return l10n.rankNovice;
      case Rank.seeker:
        return l10n.rankSeeker;
      case Rank.guardian:
        return l10n.rankGuardian;
      case Rank.master:
        return l10n.rankMaster;
      case Rank.wanderer:
        return l10n.rankWanderer;
      case Rank.awakened:
        return l10n.rankAwakened;
      case Rank.sage:
        return l10n.rankSage;
      case Rank.enlightened:
        return l10n.rankEnlightened;
      case Rank.legend:
        return l10n.rankLegend;
      case Rank.immortal:
        return l10n.rankImmortal;
      case Rank.divine:
        return l10n.rankDivine;
    }
  }

  /// Локализованное описание ранга.
  String description(AppLocalizations l10n) {
    switch (this) {
      case Rank.novice:
        return l10n.rankDescriptionNovice;
      case Rank.seeker:
        return l10n.rankDescriptionSeeker;
      case Rank.guardian:
        return l10n.rankDescriptionGuardian;
      case Rank.master:
        return l10n.rankDescriptionMaster;
      case Rank.wanderer:
        return l10n.rankDescriptionWanderer;
      case Rank.awakened:
        return l10n.rankDescriptionAwakened;
      case Rank.sage:
        return l10n.rankDescriptionSage;
      case Rank.enlightened:
        return l10n.rankDescriptionEnlightened;
      case Rank.legend:
        return l10n.rankDescriptionLegend;
      case Rank.immortal:
        return l10n.rankDescriptionImmortal;
      case Rank.divine:
        return l10n.rankDescriptionDivine;
    }
  }
}

/// Расширение [RankTier] методами локализации для Roadmap.
extension RankTierLocalization on RankTier {
  /// Локализованный диапазон уровней (например, "1–2 lvl" / "1–2 ур.").
  String levelRange(AppLocalizations l10n) {
    if (maxLevel == null) return l10n.rankLevelRangeOpen(minLevel.toString());
    if (minLevel == maxLevel) {
      return l10n.rankLevelRangeSingle(minLevel.toString());
    }
    return l10n.rankLevelRangeMulti(minLevel.toString(), maxLevel.toString());
  }

  /// Локализованное количество минут (например, "1.4K min" / "1,4 тыс. мин").
  String minutesFormatted(AppLocalizations l10n) {
    final n = minutesRequired;
    if (n >= 1000) {
      final value = (n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1);
      return l10n.rankMinutesRequiredThousands(value);
    }
    return l10n.rankMinutesRequired(n.toString());
  }
}
