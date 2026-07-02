import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/badge_model.dart';
import '../services/streak_service.dart';
import 'milestones_state.dart';

class MilestonesCubit extends Cubit<MilestonesState> {
  MilestonesCubit() : super(const MilestonesState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final profile = await StreakService.getProfile();
      final earnedIds = profile.earnedBadgeIds;

      BadgeModel markEarned(BadgeModel b) {
        if (earnedIds.contains(b.id)) {
          return b.copyWith(earned: true);
        }
        return b;
      }

      final streakBadges =
          buildStreakBadges().map(markEarned).toList();
      final achievementBadges =
          buildAchievementBadges().map(markEarned).toList();

      emit(state.copyWith(
        currentStreak: profile.currentStreak,
        longestStreak: profile.longestStreak,
        streakBadges: streakBadges,
        achievementBadges: achievementBadges,
        loading: false,
      ));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  void dismissHowStreaksWork() {
    emit(state.copyWith(showHowStreaksWork: false));
  }
}
