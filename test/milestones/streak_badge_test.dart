import 'package:flutter_test/flutter_test.dart';
import 'package:onepercent/battle/models/battle.dart';
import 'package:onepercent/milestones/models/streak_badge.dart';

/// A battle [days] days ago (0 = today), with an optional intra-day [minute]
/// offset so multiple battles can share a day while keeping a stable order.
Battle _b(BattleOutcome outcome, {int days = 0, int minute = 0}) {
  final now = DateTime.now();
  final base =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
  return Battle(
    id: '$outcome-$days-$minute',
    outcome: outcome,
    ts: base.add(Duration(hours: 12, minutes: minute)),
  );
}

const win = BattleOutcome.win;
const loss = BattleOutcome.loss;

void main() {
  StreakBadge badgeById(List<StreakBadge> badges, String id) =>
      badges.firstWhere((b) => b.id == id);

  group('evaluateStreakBadges (daily)', () {
    test('unlocks by consecutive clean days, not by win count', () {
      // Three clean days -> Spark(1) and Ember(3), but not Flame(7).
      final badges = evaluateStreakBadges([
        _b(win, days: 3),
        _b(win, days: 2),
        _b(win, days: 1),
      ]);
      expect(badgeById(badges, 'spark').earned, isTrue);
      expect(badgeById(badges, 'ember').earned, isTrue);
      expect(badgeById(badges, 'flame').earned, isFalse);
    });

    test('multiple wins in one day do not inflate the streak', () {
      final badges = evaluateStreakBadges([
        _b(win, days: 0, minute: 1),
        _b(win, days: 0, minute: 2),
        _b(win, days: 0, minute: 3),
      ]);
      expect(badgeById(badges, 'spark').earned, isTrue);
      expect(badgeById(badges, 'ember').earned, isFalse);
    });

    test('a loss resets progress but earned badges stay earned', () {
      final badges = evaluateStreakBadges([
        _b(win, days: 5),
        _b(win, days: 4),
        _b(win, days: 3), // Ember(3) reached here
        _b(loss, days: 2), // resets the running streak
        _b(win, days: 1),
      ]);
      final ember = badgeById(badges, 'ember');
      expect(ember.earned, isTrue);
      expect(ember.earnedDate, isNotNull);
    });
  });
}
