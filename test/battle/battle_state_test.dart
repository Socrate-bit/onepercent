import 'package:flutter_test/flutter_test.dart';
import 'package:onepercent/battle/cubit/battle_state.dart';
import 'package:onepercent/battle/models/battle.dart';

/// Builds a battle [days] days ago (0 = today) with an optional intra-day
/// offset so multiple battles can share a day yet keep a stable order.
Battle _b(BattleOutcome outcome, {int days = 0, int minute = 0, String? id}) {
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
  return Battle(
    id: id ?? '$outcome-$days-$minute',
    outcome: outcome,
    ts: base.add(Duration(hours: 12, minutes: minute)),
  );
}

const win = BattleOutcome.win;
const loss = BattleOutcome.loss;

void main() {
  group('currentStreak (clean days)', () {
    test('is 0 when there are no battles', () {
      expect(const BattleState().currentStreak, 0);
    });

    test('counts consecutive clean days up to the latest active day', () {
      // oldest -> newest
      final s = BattleState(battles: [
        _b(loss, days: 5),
        _b(win, days: 4),
        _b(win, days: 3),
        _b(win, days: 2),
      ]);
      expect(s.currentStreak, 3);
    });

    test('multiple wins on the same day count as one day', () {
      final s = BattleState(battles: [
        _b(win, days: 1, minute: 1),
        _b(win, days: 1, minute: 2),
        _b(win, days: 0, minute: 1),
        _b(win, days: 0, minute: 2),
      ]);
      expect(s.currentStreak, 2);
    });

    test('a frozen (empty) day between clean days does not break it', () {
      // wins 5 and 2 days ago; days 4 and 3 have no battles at all.
      final s = BattleState(battles: [
        _b(win, days: 5),
        _b(win, days: 2),
      ]);
      expect(s.currentStreak, 2);
    });

    test('is 0 when the latest active day had a loss', () {
      final s = BattleState(battles: [
        _b(win, days: 3),
        _b(win, days: 2),
        _b(loss, days: 0),
      ]);
      expect(s.currentStreak, 0);
    });

    test('a loss breaks a day even if that day also had a win', () {
      final s = BattleState(battles: [
        _b(win, days: 1),
        _b(win, days: 0, minute: 1),
        _b(loss, days: 0, minute: 2),
      ]);
      expect(s.currentStreak, 0);
    });

    test('resets after a loss day even with earlier clean days', () {
      final s = BattleState(battles: [
        _b(win, days: 6),
        _b(win, days: 5),
        _b(loss, days: 4),
        _b(win, days: 3),
      ]);
      expect(s.currentStreak, 1);
    });
  });

  group('bestStreak (clean days)', () {
    test('is 0 with no battles', () {
      expect(const BattleState().bestStreak, 0);
    });

    test('finds the longest run of clean days across history', () {
      final s = BattleState(battles: [
        _b(win, days: 10),
        _b(win, days: 9),
        _b(loss, days: 8),
        _b(win, days: 7),
        _b(win, days: 6),
        _b(win, days: 5),
        _b(win, days: 4),
        _b(loss, days: 3),
        _b(win, days: 2),
      ]);
      expect(s.bestStreak, 4);
    });

    test('counts a clean day once regardless of how many wins it holds', () {
      final s = BattleState(battles: [
        _b(win, days: 2, minute: 1),
        _b(win, days: 2, minute: 2),
        _b(win, days: 1),
      ]);
      expect(s.bestStreak, 2);
    });

    test('best streak can be the current (ongoing) streak', () {
      final s = BattleState(battles: [
        _b(loss, days: 3),
        _b(win, days: 2),
        _b(win, days: 1),
        _b(win, days: 0),
      ]);
      expect(s.bestStreak, 3);
      expect(s.currentStreak, 3);
    });
  });

  group('windowed aggregates', () {
    test('wins/losses/battles/winRate over all time', () {
      final s = BattleState(
        range: StatsRange.all,
        battles: [
          _b(win, days: 200),
          _b(loss, days: 100),
          _b(win, days: 2),
          _b(win, days: 1),
        ],
      );
      expect(s.wins, 3);
      expect(s.losses, 1);
      expect(s.battlesFought, 4);
      expect(s.winRate, closeTo(75.0, 0.001));
    });

    test('winRate is 0 when the window is empty', () {
      const s = BattleState(range: StatsRange.last7);
      expect(s.winRate, 0);
      expect(s.battlesFought, 0);
    });

    test('last7 excludes battles older than 7 days', () {
      final s = BattleState(
        range: StatsRange.last7,
        battles: [
          _b(win, days: 20), // out of window
          _b(loss, days: 8), // out of window (>= 7 days ago boundary)
          _b(win, days: 6), // in
          _b(win, days: 0), // in
        ],
      );
      expect(s.battlesFought, 2);
      expect(s.wins, 2);
      expect(s.losses, 0);
    });

    test('totalWinsAllTime ignores the range window', () {
      final s = BattleState(
        range: StatsRange.last7,
        battles: [
          _b(win, days: 90),
          _b(win, days: 1),
          _b(loss, days: 0),
        ],
      );
      expect(s.totalWinsAllTime, 2);
      expect(s.wins, 1); // windowed
    });
  });

  group('dayTallies & cumulativeSeries', () {
    test('groups battles by day and orders oldest first', () {
      final s = BattleState(
        range: StatsRange.all,
        battles: [
          _b(win, days: 2, minute: 1),
          _b(loss, days: 2, minute: 2),
          _b(win, days: 2, minute: 3),
          _b(win, days: 0, minute: 1),
        ],
      );
      final t = s.dayTallies;
      expect(t.length, 2);
      expect(t.first.wins, 2);
      expect(t.first.losses, 1);
      expect(t.first.mostlyWins, isTrue);
      expect(t.last.wins, 1);
    });

    test('cumulative series accumulates wins and losses over days', () {
      final s = BattleState(
        range: StatsRange.all,
        battles: [
          _b(win, days: 3),
          _b(loss, days: 2),
          _b(win, days: 1),
        ],
      );
      final series = s.cumulativeSeries;
      expect(series.length, 3);
      expect(series[0].cumulativeWins, 1);
      expect(series[0].cumulativeLosses, 0);
      expect(series[1].cumulativeWins, 1);
      expect(series[1].cumulativeLosses, 1);
      expect(series[2].cumulativeWins, 2);
      expect(series[2].cumulativeLosses, 1);
    });
  });
}
