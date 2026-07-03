import 'package:equatable/equatable.dart';

import '../models/battle.dart';
import '../util/discipline_percentile.dart';
import '../util/streaks.dart';

/// Time window applied to the aggregate Stats metrics.
enum StatsRange {
  last7(7, '7 DAYS'),
  last30(30, '30 DAYS'),
  last90(90, '90 DAYS'),
  all(null, 'ALL TIME');

  const StatsRange(this.days, this.label);

  /// Number of days in the window, or null for all-time.
  final int? days;
  final String label;
}

/// A single day's win/loss tally, used by the calendar heatmap.
class DayTally extends Equatable {
  final DateTime day; // date-only (midnight local)
  final int wins;
  final int losses;

  const DayTally({required this.day, required this.wins, required this.losses});

  int get total => wins + losses;
  bool get mostlyWins => wins >= losses;

  @override
  List<Object?> get props => [day, wins, losses];
}

/// One point on the cumulative progress chart.
class SeriesPoint extends Equatable {
  final DateTime day;
  final int cumulativeWins;
  final int cumulativeLosses;

  const SeriesPoint({
    required this.day,
    required this.cumulativeWins,
    required this.cumulativeLosses,
  });

  @override
  List<Object?> get props => [day, cumulativeWins, cumulativeLosses];
}

/// Immutable state for the battle feature. Holds the full battle list plus the
/// selected [range]; all analytics are derived on demand so there is nothing
/// to keep in sync.
class BattleState extends Equatable {
  /// All battles, oldest first.
  final List<Battle> battles;
  final StatsRange range;
  final bool loading;
  final String? error;

  const BattleState({
    this.battles = const [],
    this.range = StatsRange.last30,
    this.loading = true,
    this.error,
  });

  BattleState copyWith({
    List<Battle>? battles,
    StatsRange? range,
    bool? loading,
    Object? error = _sentinel,
  }) {
    return BattleState(
      battles: battles ?? this.battles,
      range: range ?? this.range,
      loading: loading ?? this.loading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const Object _sentinel = Object();

  // --- All-time streaks (window does not apply) ---------------------------

  /// Consecutive clean days (a win, no loss) up to the most recent active day;
  /// 0 if that day had a loss. Empty days in between are frozen, not breaks.
  int get currentStreak => dailyCurrentStreak(battles);

  /// Longest run of consecutive clean days ever recorded.
  int get bestStreak => dailyBestStreak(battles);

  /// Lifetime total wins (not windowed) — shown on Home.
  int get totalWinsAllTime => battles.where((b) => b.isWin).length;

  // --- This week (last 7 days) --------------------------------------------

  /// Battles recorded in the last 7 days (today included).
  List<Battle> get _thisWeekBattles {
    final cutoff = _dateOnly(DateTime.now()).subtract(const Duration(days: 6));
    return battles.where((b) => !_dateOnly(b.ts).isBefore(cutoff)).toList();
  }

  /// Number of battles fought this week.
  int get battlesThisWeek => _thisWeekBattles.length;

  /// Win rate this week as a percentage (0 when no battles this week).
  double get winRateThisWeek {
    final week = _thisWeekBattles;
    if (week.isEmpty) return 0;
    return week.where((b) => b.isWin).length / week.length * 100;
  }

  // --- Windowed aggregates ------------------------------------------------

  /// Battles falling inside the selected [range].
  List<Battle> get windowBattles {
    final days = range.days;
    if (days == null) return battles;
    final cutoff = _dateOnly(DateTime.now()).subtract(Duration(days: days - 1));
    return battles.where((b) => !_dateOnly(b.ts).isBefore(cutoff)).toList();
  }

  int get wins => windowBattles.where((b) => b.isWin).length;
  int get losses => windowBattles.where((b) => b.isLoss).length;
  int get battlesFought => windowBattles.length;

  /// Win rate as a percentage (0 when no battles in window).
  double get winRate =>
      battlesFought == 0 ? 0 : wins / battlesFought * 100;

  /// Where this window's win rate places the user in the general population,
  /// as a percentile (0–100), or null until there are enough battles to judge.
  /// See [DisciplinePercentile] for the empirical basis.
  double? get disciplinePercentile =>
      DisciplinePercentile.forRecord(wins, battlesFought);

  /// Per-day tallies inside the window, oldest day first.
  List<DayTally> get dayTallies {
    final map = <DateTime, List<int>>{}; // day -> [wins, losses]
    for (final b in windowBattles) {
      final day = _dateOnly(b.ts);
      final entry = map.putIfAbsent(day, () => [0, 0]);
      if (b.isWin) {
        entry[0]++;
      } else {
        entry[1]++;
      }
    }
    final days = map.keys.toList()..sort();
    return days
        .map((d) => DayTally(day: d, wins: map[d]![0], losses: map[d]![1]))
        .toList();
  }

  /// Cumulative wins/losses over the window, one point per active day.
  List<SeriesPoint> get cumulativeSeries {
    var wins = 0;
    var losses = 0;
    return dayTallies.map((t) {
      wins += t.wins;
      losses += t.losses;
      return SeriesPoint(day: t.day, cumulativeWins: wins, cumulativeLosses: losses);
    }).toList();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  List<Object?> get props => [battles, range, loading, error];
}
