import '../models/badge_model.dart';

class MilestonesState {
  final int currentStreak;
  final int longestStreak;
  final List<BadgeModel> streakBadges;
  final List<BadgeModel> achievementBadges;
  final List<BadgeModel> sleepAchievementBadges;
  final bool showHowStreaksWork;
  final bool loading;

  int get badgesEarned => [
        ...streakBadges,
        ...achievementBadges,
        ...sleepAchievementBadges,
      ].where((b) => b.earned).length;

  int get totalBadges =>
      streakBadges.length +
      achievementBadges.length +
      sleepAchievementBadges.length;

  const MilestonesState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.streakBadges = const [],
    this.achievementBadges = const [],
    this.sleepAchievementBadges = const [],
    this.showHowStreaksWork = true,
    this.loading = true,
  });

  MilestonesState copyWith({
    int? currentStreak,
    int? longestStreak,
    List<BadgeModel>? streakBadges,
    List<BadgeModel>? achievementBadges,
    List<BadgeModel>? sleepAchievementBadges,
    bool? showHowStreaksWork,
    bool? loading,
  }) =>
      MilestonesState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        streakBadges: streakBadges ?? this.streakBadges,
        achievementBadges: achievementBadges ?? this.achievementBadges,
        sleepAchievementBadges:
            sleepAchievementBadges ?? this.sleepAchievementBadges,
        showHowStreaksWork: showHowStreaksWork ?? this.showHowStreaksWork,
        loading: loading ?? this.loading,
      );
}
