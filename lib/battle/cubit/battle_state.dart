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
  int get totalWinsAllTime => _weight(battles.where((b) => b.isWin));

  /// Whether the day has already been validated today (a validated-source win
  /// logged on the current calendar day). Drives the Validate Day lock.
  bool get validatedToday {
    final now = DateTime.now();
    return battles.any((b) =>
        b.source == BattleSource.validated &&
        b.ts.year == now.year &&
        b.ts.month == now.month &&
        b.ts.day == now.day);
  }

  /// Whether any loss was logged today. A day can only be validated when it is
  /// genuinely clean, so this blocks the Validate Day action.
  bool get hasLossToday {
    final now = DateTime.now();
    return battles.any((b) =>
        b.isLoss &&
        b.ts.year == now.year &&
        b.ts.month == now.month &&
        b.ts.day == now.day);
  }

  /// Sum of the [weight] over [items] — the weighted count of battles.
  static int _weight(Iterable<Battle> items) =>
      items.fold(0, (sum, b) => sum + b.weight);

  // --- This week (from Monday) --------------------------------------------

  /// Battles recorded since the most recent Monday (this calendar week, today
  /// included).
  List<Battle> get _thisWeekBattles {
    final today = _dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return battles.where((b) => !_dateOnly(b.ts).isBefore(monday)).toList();
  }

  /// Number of battles fought this week.
  int get battlesThisWeek => _weight(_thisWeekBattles);

  /// Wins recorded this week.
  int get winsThisWeek => _weight(_thisWeekBattles.where((b) => b.isWin));

  /// Losses recorded this week.
  int get lossesThisWeek => _weight(_thisWeekBattles.where((b) => b.isLoss));

  /// Win rate this week as a percentage (0 when no battles this week).
  double get winRateThisWeek {
    final total = battlesThisWeek;
    if (total == 0) return 0;
    return winsThisWeek / total * 100;
  }

  // --- Windowed aggregates ------------------------------------------------

  /// Battles falling inside the selected [range].
  List<Battle> get windowBattles {
    final days = range.days;
    if (days == null) return battles;
    final cutoff = _dateOnly(DateTime.now()).subtract(Duration(days: days - 1));
    return battles.where((b) => !_dateOnly(b.ts).isBefore(cutoff)).toList();
  }

  int get wins => _weight(windowBattles.where((b) => b.isWin));
  int get losses => _weight(windowBattles.where((b) => b.isLoss));
  int get battlesFought => _weight(windowBattles);

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
        entry[0] += b.weight;
      } else {
        entry[1] += b.weight;
      }
    }
    final days = map.keys.toList()..sort();
    return days
        .map((d) => DayTally(day: d, wins: map[d]![0], losses: map[d]![1]))
        .toList();
  }

  /// Cumulative wins/losses over the window. Points are aggregated per day for
  /// the short ranges, weekly for [StatsRange.last90], and monthly for
  /// [StatsRange.all] so the chart stays legible over long spans.
  List<SeriesPoint> get cumulativeSeries {
    final buckets = <DateTime, List<int>>{}; // bucketStart -> [wins, losses]
    for (final t in dayTallies) {
      final key = _bucketStart(t.day);
      final entry = buckets.putIfAbsent(key, () => [0, 0]);
      entry[0] += t.wins;
      entry[1] += t.losses;
    }
    final keys = buckets.keys.toList()..sort();
    var wins = 0;
    var losses = 0;
    return keys.map((k) {
      wins += buckets[k]![0];
      losses += buckets[k]![1];
      return SeriesPoint(day: k, cumulativeWins: wins, cumulativeLosses: losses);
    }).toList();
  }

  /// The bucket a [day] falls into for [cumulativeSeries], per the active range:
  /// weekly (Monday) for 90 days, monthly for all-time, daily otherwise.
  DateTime _bucketStart(DateTime day) {
    switch (range) {
      case StatsRange.last90:
        return day.subtract(Duration(days: day.weekday - 1));
      case StatsRange.all:
        return DateTime(day.year, day.month, 1);
      default:
        return day;
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  List<Object?> get props => [battles, range, loading, error];
}
