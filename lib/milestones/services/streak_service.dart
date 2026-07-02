import 'package:cloud_firestore/cloud_firestore.dart';

import '../../alarms/services/alarm_firestore_service.dart';
import '../../subscription/services/analytics_service.dart';
import '../../auth/auth_service.dart';
import '../../activity/models/activity.dart';
import '../../activity/services/activity_service.dart';
import '../models/badge_model.dart';

/// Streak freeze rules — tweak per-project. A "freeze" is a missed day that
/// doesn't break the streak, simulating a grace period.
const kStreakMaxFreezesPerWeek = 2;
const kStreakMaxConsecutiveFreezes = 2;

/// Per-day status used by the home weekly widget.
enum DayStatus { none, done, frozen }

/// Result of [StreakService.computeStreak].
class StreakResult {
  /// Number of consecutive days (activities + freezes) walking backward from today.
  final int streak;

  /// Sun..Sat statuses for the current calendar week.
  final List<DayStatus> weekDays;

  const StreakResult({required this.streak, required this.weekDays});
}

class StreakProfile {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalActivities;
  final List<String> earnedBadgeIds;

  const StreakProfile({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.totalActivities = 0,
    this.earnedBadgeIds = const [],
  });

  factory StreakProfile.fromMap(Map<String, dynamic> data) => StreakProfile(
        currentStreak: (data['currentStreak'] as int?) ?? 0,
        longestStreak: (data['longestStreak'] as int?) ?? 0,
        lastActivityDate: data['lastActivityDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                data['lastActivityDate'] as int)
            : null,
        totalActivities: (data['totalActivities'] as int?) ??
            (data['totalWakeups'] as int?) ??
            0,
        earnedBadgeIds:
            List<String>.from(data['earnedBadgeIds'] as List? ?? []),
      );

  Map<String, dynamic> toMap() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActivityDate': lastActivityDate?.millisecondsSinceEpoch,
        'totalActivities': totalActivities,
        'earnedBadgeIds': earnedBadgeIds,
      };
}

class ActivityResult {
  final int newStreak;
  final List<BadgeModel> newlyEarnedBadges;
  const ActivityResult({
    required this.newStreak,
    required this.newlyEarnedBadges,
  });
}

class StreakService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _profileDoc =>
      _db
          .collection('users')
          .doc(AuthService.uid)
          .collection('meta')
          .doc('profile');

  static Future<StreakProfile> getProfile() async {
    final doc = await _profileDoc.get();
    if (!doc.exists || doc.data() == null) return const StreakProfile();
    return StreakProfile.fromMap(doc.data()!);
  }

  /// Real-time stream of the user's streak profile.
  static Stream<StreakProfile> watchProfile() {
    return _profileDoc.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return const StreakProfile();
      return StreakProfile.fromMap(doc.data()!);
    });
  }

  /// Called when the user successfully completes an activity (e.g. dismisses
  /// an alarm). Updates streak + evaluates badge unlocks.
  static Future<ActivityResult> onActivityCompleted({
    required String activityId,
    int durationSeconds = 0,
  }) async {
    final profile = await getProfile();
    final now = DateTime.now();

    // Already logged today — no streak update.
    if (profile.lastActivityDate != null &&
        _isSameDay(profile.lastActivityDate!, now)) {
      return ActivityResult(
        newStreak: profile.currentStreak,
        newlyEarnedBadges: const [],
      );
    }

    final newStreak = await computeCurrentStreak();
    final newLongest =
        newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

    final newlyEarned = <BadgeModel>[];
    final updatedBadgeIds = List<String>.from(profile.earnedBadgeIds);

    // Streak-tier badges
    for (final badge in buildStreakBadges()) {
      if (!updatedBadgeIds.contains(badge.id) &&
          badge.requiredDays != null &&
          newStreak >= badge.requiredDays!) {
        newlyEarned.add(badge.copyWith(earned: true, earnedDate: now));
        updatedBadgeIds.add(badge.id);
      }
    }

    // Achievement badges — placeholders. Define per-project conditions here.
    // Example: if (!updatedBadgeIds.contains('challenge_1') && /* condition */) { ... }

    await _profileDoc.set({
      'currentStreak': newStreak,
      'longestStreak': newLongest,
      'lastActivityDate': now.millisecondsSinceEpoch,
      'earnedBadgeIds': updatedBadgeIds,
    }, SetOptions(merge: true));

    for (final badge in newlyEarned) {
      AnalyticsService.capture(
        AnalyticsService.badgeEarned,
        {'challenge_id': badge.id},
      );
    }

    return ActivityResult(
      newStreak: newStreak,
      newlyEarnedBadges: newlyEarned,
    );
  }

  static Future<bool> hasLoggedActivityToday() async {
    final profile = await getProfile();
    if (profile.lastActivityDate == null) return false;
    return _isSameDay(profile.lastActivityDate!, DateTime.now());
  }

  /// Walks backward from today through [activities], applying freeze rules.
  static StreakResult computeStreak({
    required List<Activity> activities,
    DateTime? stopDate,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    final activityDays = <String>{};
    DateTime? oldestActivityDay;
    for (final a in activities) {
      if (!a.completed) continue;
      final d = _dateOnly(a.timestamp);
      activityDays.add(_dateStr(d));
      if (oldestActivityDay == null || d.isBefore(oldestActivityDay)) {
        oldestActivityDay = d;
      }
    }

    final startOfDisplayWeek = _startOfDisplayWeek(today);
    final endOfDisplayWeek = _addDays(startOfDisplayWeek, 6);
    final weekDays = List<DayStatus>.filled(7, DayStatus.none);
    for (int i = 0; i < 7; i++) {
      final d = _addDays(startOfDisplayWeek, i);
      if (activityDays.contains(_dateStr(d))) {
        weekDays[i] = DayStatus.done;
      }
    }

    final effectiveStop =
        stopDate != null ? _dateOnly(stopDate) : oldestActivityDay;
    if (effectiveStop == null) {
      return StreakResult(streak: 0, weekDays: weekDays);
    }

    int streak = 0;
    int weekFreezes = 0;
    int consecutiveFreezes = 0;
    DateTime currentMonday = _getMondayOfWeek(today);
    DateTime cursor = today;

    while (!cursor.isBefore(effectiveStop)) {
      final cursorMonday = _getMondayOfWeek(cursor);
      if (!_isSameDay(cursorMonday, currentMonday)) {
        weekFreezes = 0;
        currentMonday = cursorMonday;
      }

      if (activityDays.contains(_dateStr(cursor))) {
        streak++;
        consecutiveFreezes = 0;
      } else if (weekFreezes < kStreakMaxFreezesPerWeek &&
          consecutiveFreezes < kStreakMaxConsecutiveFreezes) {
        weekFreezes++;
        consecutiveFreezes++;
        if (!_isSameDay(cursor, today) &&
            !cursor.isBefore(startOfDisplayWeek) &&
            !cursor.isAfter(endOfDisplayWeek)) {
          final idx = cursor.difference(startOfDisplayWeek).inDays;
          weekDays[idx] = DayStatus.frozen;
        }
      } else {
        break;
      }

      cursor = _addDays(cursor, -1);
    }

    return StreakResult(streak: streak, weekDays: weekDays);
  }

  static Future<int> computeCurrentStreak([
    List<Activity>? activities,
  ]) async {
    activities ??= await ActivityService.getActivities(
      limit: 400,
      includeIncomplete: false,
    );
    return computeStreak(activities: activities).streak;
  }

  /// Returns the earliest createdAt date across all alarms, or null if none.
  static Future<DateTime?> getFirstAlarmCreatedDate() async {
    final alarms = await AlarmFirestoreService.getAlarms();
    if (alarms.isEmpty) return null;
    alarms.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return alarms.first.createdAt;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _getMondayOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  static DateTime _startOfDisplayWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
