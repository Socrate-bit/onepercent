import 'package:equatable/equatable.dart';

import '../models/battle.dart';

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

  /// Consecutive wins since the last loss (0 if the most recent battle lost).
  int get currentStreak {
    var streak = 0;
    for (var i = battles.length - 1; i >= 0; i--) {
      if (battles[i].isWin) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Longest run of consecutive wins ever recorded.
  int get bestStreak {
    var best = 0;
    var run = 0;
    for (final b in battles) {
      if (b.isWin) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    return best;
  }

  /// Lifetime total wins (not windowed) — shown on Home.
  int get totalWinsAllTime => battles.where((b) => b.isWin).length;

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
