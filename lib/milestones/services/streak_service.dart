import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/alarms/services/alarm_firestore_service.dart';
import '../../../features/missions/models/mission.dart';
import '../../subscription/services/analytics_service.dart';
import '../../auth/auth_service.dart';
import '../../../features/wakeup/models/wakeup_session.dart';
import '../../../features/wakeup/services/history_service.dart';
import '../models/badge_model.dart';

/// Per-day status used by the home weekly widget.
enum DayStatus { none, done, frozen, missed }

/// Result of [StreakService.computeStreak].
class StreakResult {
  /// Number of consecutive days (sessions + freezes) walking backward from today.
  final int streak;

  /// Sun..Sat statuses for the current calendar week.
  final List<DayStatus> weekDays;

  const StreakResult({required this.streak, required this.weekDays});
}

class StreakProfile {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWakeupDate;
  final int totalWakeups;
  final List<String> earnedBadgeIds;
  final List<String> usedSoundIds;
  // Mission types completed on wake-up alarms (drives the wake "Versatile" badge).
  final List<String> usedMissionTypeNames;
  // Mission types completed on sleep alarms (drives the sleep "Dreamer" badge).
  final List<String> usedSleepMissionTypeNames;

  const StreakProfile({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWakeupDate,
    this.totalWakeups = 0,
    this.earnedBadgeIds = const [],
    this.usedSoundIds = const [],
    this.usedMissionTypeNames = const [],
    this.usedSleepMissionTypeNames = const [],
  });

  factory StreakProfile.fromMap(Map<String, dynamic> data) => StreakProfile(
        currentStreak: (data['currentStreak'] as int?) ?? 0,
        longestStreak: (data['longestStreak'] as int?) ?? 0,
        lastWakeupDate: data['lastWakeupDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                data['lastWakeupDate'] as int)
            : null,
        totalWakeups: (data['totalWakeups'] as int?) ?? 0,
        earnedBadgeIds:
            List<String>.from(data['earnedBadgeIds'] as List? ?? []),
        usedSoundIds: List<String>.from(data['usedSoundIds'] as List? ?? []),
        usedMissionTypeNames:
            List<String>.from(data['usedMissionTypeNames'] as List? ?? []),
        usedSleepMissionTypeNames: List<String>.from(
            data['usedSleepMissionTypeNames'] as List? ?? []),
      );

  Map<String, dynamic> toMap() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastWakeupDate': lastWakeupDate?.millisecondsSinceEpoch,
        'totalWakeups': totalWakeups,
        'earnedBadgeIds': earnedBadgeIds,
        'usedSoundIds': usedSoundIds,
        'usedMissionTypeNames': usedMissionTypeNames,
        'usedSleepMissionTypeNames': usedSleepMissionTypeNames,
      };
}

/// Mission types that count toward the sleep "Dreamer" badge (all 6 wind-down
/// missions).
const _sleepMissionTypes = <MissionType>[
  MissionType.breathing,
  MissionType.meditation,
  MissionType.gratefulness,
  MissionType.routine,
  MissionType.bedPhoto,
  MissionType.affirmation,
];

class WakeupResult {
  final int newStreak;
  final List<BadgeModel> newlyEarnedBadges;
  const WakeupResult({required this.newStreak, required this.newlyEarnedBadges});
}

class StreakService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _profileDoc =>
      _db
          .collection('users')
          .doc(AuthService.uid)
          .collection('meta')
          .doc('profile');

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

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

  /// Called when the user successfully dismisses an alarm.
  /// [sessionId] is the Firestore session document ID (already completed).
  static Future<WakeupResult> onWakeupCompleted({
    required String sessionId,
    String? soundId,
    int timeTakenSeconds = 0,
    MissionType? missionType,
    bool isSleep = false,
  }) async {
    final profile = await getProfile();
    final now = DateTime.now();

    // Streak advances at most once per day, but later same-day completions must
    // still be evaluated for badges — e.g. a sleep alarm the same evening as the
    // morning wake-up shares the calendar day yet should still award sleep badges.
    final alreadyToday = profile.lastWakeupDate != null &&
        _isSameDay(profile.lastWakeupDate!, now);

    // -------------------------------------------------------------------------
    // Streak: walk backward from today; freezes (max 2/week, max 2 in a row)
    // bridge missed days; first session date stops the walk.
    // -------------------------------------------------------------------------
    final newStreak =
        alreadyToday ? profile.currentStreak : await computeCurrentStreak();
    final newLongest =
        newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

    // -------------------------------------------------------------------------
    // Badge evaluation
    // -------------------------------------------------------------------------
    final allStreakBadges = buildStreakBadges();
    final newlyEarned = <BadgeModel>[];
    final updatedBadgeIds = List<String>.from(profile.earnedBadgeIds);

    // Streak badges (shared across wake-up and sleep alarms).
    for (final badge in allStreakBadges) {
      if (!updatedBadgeIds.contains(badge.id) &&
          badge.requiredDays != null &&
          newStreak >= badge.requiredDays!) {
        newlyEarned.add(badge.copyWith(earned: true, earnedDate: now));
        updatedBadgeIds.add(badge.id);
      }
    }

    // Variety trackers accrue per alarm type so wake badges derive purely from
    // wake-up alarms and sleep badges purely from sleep alarms.
    final updatedSounds = List<String>.from(profile.usedSoundIds);
    final updatedMissions = List<String>.from(profile.usedMissionTypeNames);
    final updatedSleepMissions =
        List<String>.from(profile.usedSleepMissionTypeNames);

    void earn(List<BadgeModel> pool, String id) {
      if (updatedBadgeIds.contains(id)) return;
      newlyEarned.add(
          pool.firstWhere((b) => b.id == id).copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add(id);
    }

    // -------------------------------------------------------------------------
    // Achievement badges — gated by alarm type so each set only ever unlocks on
    // its matching alarm. Sleep alarms never award wake-up badges and vice versa.
    // -------------------------------------------------------------------------
    if (isSleep) {
      final sleepBadges = buildSleepAchievementBadges();

      // First Night: first completed sleep alarm.
      earn(sleepBadges, 'first_night');

      // Early to Bed: wind down in the evening, before 10 PM (excludes
      // after-midnight completions, which are the opposite of "early").
      if (now.hour >= 18 && now.hour < 22) earn(sleepBadges, 'early_to_bed');

      // Calm Mind: a meditation or breathing wind-down.
      if (missionType == MissionType.meditation ||
          missionType == MissionType.breathing) {
        earn(sleepBadges, 'calm_mind');
      }

      // Dreamer: all wind-down mission types used on sleep alarms.
      if (missionType != null &&
          missionType != MissionType.none &&
          !updatedSleepMissions.contains(missionType.name)) {
        updatedSleepMissions.add(missionType.name);
      }
      if (_sleepMissionTypes.every((t) => updatedSleepMissions.contains(t.name))) {
        earn(sleepBadges, 'dreamer');
      }

      // Well Rested: a 7-day streak reached via a sleep alarm.
      if (newStreak >= 7) earn(sleepBadges, 'well_rested');

      // No Nights Off: 30 consecutive nights.
      if (newStreak >= 30) earn(sleepBadges, 'no_nights_off');
    } else {
      final achieveBadges = buildAchievementBadges();

      // Blitz: dismissed in under 15s.
      if (timeTakenSeconds < 15 && timeTakenSeconds > 0) {
        earn(achieveBadges, 'blitz');
      }

      // First Light: before 5:30 AM.
      if (now.hour < 5 || (now.hour == 5 && now.minute < 30)) {
        earn(achieveBadges, 'first_light');
      }

      // Audiophile: 4+ distinct sounds on wake-up alarms.
      if (soundId != null &&
          soundId.isNotEmpty &&
          !updatedSounds.contains(soundId)) {
        updatedSounds.add(soundId);
      }
      if (updatedSounds.length >= 4) earn(achieveBadges, 'audiophile');

      // Converted: streak of 7 reached via a wake-up alarm.
      if (newStreak >= 7) earn(achieveBadges, 'converted');

      // Versatile: all mission types used on wake-up alarms.
      if (missionType != null &&
          missionType != MissionType.none &&
          !updatedMissions.contains(missionType.name)) {
        updatedMissions.add(missionType.name);
      }
      if (updatedMissions.length >=
          MissionType.values.where((t) => t != MissionType.none).length) {
        earn(achieveBadges, 'versatile');
      }

      // No Days Off: 30 consecutive days.
      if (newStreak >= 30) earn(achieveBadges, 'no_days_off');
    }

    // -------------------------------------------------------------------------
    // Save to Firestore
    // -------------------------------------------------------------------------
    await _profileDoc.set({
      'currentStreak': newStreak,
      'longestStreak': newLongest,
      'lastWakeupDate': now.millisecondsSinceEpoch,
      'earnedBadgeIds': updatedBadgeIds,
      'usedSoundIds': updatedSounds,
      'usedMissionTypeNames': updatedMissions,
      'usedSleepMissionTypeNames': updatedSleepMissions,
    }, SetOptions(merge: true));

    if (newStreak > profile.currentStreak) {
      AnalyticsService.capture(
        AnalyticsService.streakMilestone,
        {'days': newStreak},
      );
    }
    for (final badge in newlyEarned) {
      AnalyticsService.capture(
        AnalyticsService.badgeEarned,
        {'badge_id': badge.id},
      );
    }

    return WakeupResult(newStreak: newStreak, newlyEarnedBadges: newlyEarned);
  }

  static Future<bool> hasWokenUpToday() async {
    final profile = await getProfile();
    if (profile.lastWakeupDate == null) return false;
    return _isSameDay(profile.lastWakeupDate!, DateTime.now());
  }

  // ---------------------------------------------------------------------------
  // Streak computation (single source of truth)
  // ---------------------------------------------------------------------------

  /// Walks backward from today through [sessions], applying freeze rules:
  ///   - At most 2 freezes per Mon–Sun calendar week.
  ///   - At most 2 consecutive freezes in a row.
  /// The walk stops when it would cross before [stopDate]. If [stopDate] is
  /// null, the walk stops at the day of the oldest completed session — so
  /// pre-app-start days never count as misses.
  ///
  /// Returns the streak count and Sun..Sat statuses for the current calendar
  /// week (today displays as `none` when there is no completed session, even
  /// if a freeze was internally applied, because today is in-progress).
  ///
  /// [now] is injectable for testing.
  static StreakResult computeStreak({
    required List<WakeupSession> sessions,
    DateTime? stopDate,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    // Index completed sessions by date; track the oldest. Also track days that
    // had any session at all, so days with only an incomplete (missed) session
    // can be distinguished from days with no alarm.
    final sessionDays = <String>{};
    final anySessionDays = <String>{};
    final disabledDays = <String>{};
    DateTime? oldestSessionDay;
    for (final s in sessions) {
      final d = _dateOnly(s.timestamp);
      anySessionDays.add(_dateStr(d));
      if (s.screenTimeDisabled) disabledDays.add(_dateStr(d));
      if (!s.completed) continue;
      sessionDays.add(_dateStr(d));
      if (oldestSessionDay == null || d.isBefore(oldestSessionDay)) {
        oldestSessionDay = d;
      }
    }

    // Deactivating screen-time blocking forces its day to count as missed: drop
    // it from the completed set even if a wake-up also happened that day, so the
    // streak walk treats it as a (freezable) miss.
    sessionDays.removeAll(disabledDays);

    // Build the display week (Sun..Sat) with done marks; freezes filled in
    // during the walk below.
    final startOfDisplayWeek = _startOfDisplayWeek(today);
    final endOfDisplayWeek = _addDays(startOfDisplayWeek, 6);
    final weekDays = List<DayStatus>.filled(7, DayStatus.none);
    for (int i = 0; i < 7; i++) {
      final d = _addDays(startOfDisplayWeek, i);
      if (sessionDays.contains(_dateStr(d))) {
        weekDays[i] = DayStatus.done;
      }
    }

    final effectiveStop =
        stopDate != null ? _dateOnly(stopDate) : oldestSessionDay;
    if (effectiveStop == null) {
      return StreakResult(streak: 0, weekDays: weekDays);
    }

    int streak = 0;
    int weekFreezes = 0;
    int consecutiveFreezes = 0;
    DateTime currentMonday = _getMondayOfWeek(today);
    DateTime cursor = today;

    while (!cursor.isBefore(effectiveStop)) {
      // Reset the per-week freeze budget when crossing a Monday backward.
      final cursorMonday = _getMondayOfWeek(cursor);
      if (!_isSameDay(cursorMonday, currentMonday)) {
        weekFreezes = 0;
        currentMonday = cursorMonday;
      }

      if (sessionDays.contains(_dateStr(cursor))) {
        streak++;
        consecutiveFreezes = 0;
      } else if (weekFreezes < 2 && consecutiveFreezes < 2) {
        weekFreezes++;
        consecutiveFreezes++;
        // Mark the display week as frozen for past days only — today stays
        // `none` because it is still in-progress visually.
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

    // Mark past display-week days that had an alarm but no completed session as
    // missed. Done/frozen days keep their status; today and future stay `none`.
    for (int i = 0; i < 7; i++) {
      final d = _addDays(startOfDisplayWeek, i);
      if (weekDays[i] != DayStatus.none) continue;
      if (!d.isBefore(today)) continue; // skip today and future
      if (anySessionDays.contains(_dateStr(d))) {
        weekDays[i] = DayStatus.missed;
      }
    }

    return StreakResult(streak: streak, weekDays: weekDays);
  }

  /// Backward-compatible wrapper. [firstAlarmDate] is accepted but ignored —
  /// the walk now stops at the oldest session date.
  static Future<int> computeCurrentStreak([
    List<WakeupSession>? sessions,
    DateTime? firstAlarmDate,
  ]) async {
    sessions ??= await HistoryService.getSessions(
      limit: 400,
      includeIncomplete: true, // needed so screen-time-disabled days are misses
    );
    return computeStreak(sessions: sessions).streak;
  }

  /// Returns the earliest createdAt date across all alarms, or null if none.
  static Future<DateTime?> getFirstAlarmCreatedDate() async {
    final alarms = await AlarmFirestoreService.getAlarms();
    if (alarms.isEmpty) return null;
    alarms.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return alarms.first.createdAt;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns the Monday of the ISO week containing [date].
  static DateTime _getMondayOfWeek(DateTime date) {
    // weekday: Mon=1 … Sun=7
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Returns the Sunday that begins the display week containing [date].
  static DateTime _startOfDisplayWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7; // Sun=7→0
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
