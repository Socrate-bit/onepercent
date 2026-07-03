import '../models/battle.dart';

/// Daily-streak logic shared by the Home/Stats displays and the milestone
/// badges, so there is a single source of truth.
///
/// A day counts toward the streak only when it is a *clean day*: the user won
/// at least one battle and lost none that day. The rules:
///
///  * clean day (a win, no loss) -> extends the streak by one,
///  * a day with any loss        -> resets the streak to zero,
///  * a day with no battles      -> frozen: it neither extends nor breaks it.
///
/// Streaks are all-time — the Stats range window never applies to them.

/// A single day's outcome roll-up.
typedef DayOutcome = ({DateTime day, bool hasWin, bool hasLoss});

/// Per-day outcome roll-up across [battles], oldest day first. Only days with
/// at least one battle are present, so callers treat gaps as frozen days.
List<DayOutcome> dailyOutcomes(List<Battle> battles) {
  final map = <DateTime, List<bool>>{}; // day -> [hasWin, hasLoss]
  for (final b in battles) {
    final day = DateTime(b.ts.year, b.ts.month, b.ts.day);
    final entry = map.putIfAbsent(day, () => [false, false]);
    if (b.isWin) {
      entry[0] = true;
    } else {
      entry[1] = true;
    }
  }
  final days = map.keys.toList()..sort();
  return [
    for (final d in days) (day: d, hasWin: map[d]![0], hasLoss: map[d]![1]),
  ];
}

/// Consecutive clean days up to the most recent active day (0 when that day
/// had a loss). Frozen days between clean days do not break the run.
int dailyCurrentStreak(List<Battle> battles) {
  final days = dailyOutcomes(battles);
  var streak = 0;
  for (var i = days.length - 1; i >= 0; i--) {
    if (days[i].hasLoss) break;
    streak++; // an active day with no loss is a clean win-day
  }
  return streak;
}

/// Longest run of consecutive clean days ever recorded.
int dailyBestStreak(List<Battle> battles) {
  var best = 0, run = 0;
  for (final d in dailyOutcomes(battles)) {
    if (d.hasLoss) {
      run = 0;
    } else {
      run++;
      if (run > best) best = run;
    }
  }
  return best;
}
