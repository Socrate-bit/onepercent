import 'package:flutter_test/flutter_test.dart';
import 'package:onepercent/battle/models/battle.dart';

void main() {
  group('BattleOutcome.fromName', () {
    test('maps "loss" to loss and everything else to win', () {
      expect(BattleOutcome.fromName('loss'), BattleOutcome.loss);
      expect(BattleOutcome.fromName('win'), BattleOutcome.win);
      expect(BattleOutcome.fromName('garbage'), BattleOutcome.win);
    });
  });

  group('Battle', () {
    test('isWin / isLoss reflect the outcome', () {
      final ts = DateTime(2026, 1, 1);
      expect(Battle(id: 'a', outcome: BattleOutcome.win, ts: ts).isWin, isTrue);
      expect(Battle(id: 'a', outcome: BattleOutcome.loss, ts: ts).isLoss, isTrue);
    });

    test('toMap serializes outcome name and epoch millis', () {
      final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final map = Battle(id: 'x', outcome: BattleOutcome.loss, ts: ts).toMap();
      expect(map['outcome'], 'loss');
      expect(map['ts'], 1700000000000);
    });

    test('value equality via Equatable', () {
      final ts = DateTime(2026, 1, 1);
      expect(
        Battle(id: 'x', outcome: BattleOutcome.win, ts: ts),
        Battle(id: 'x', outcome: BattleOutcome.win, ts: ts),
      );
    });
  });
}
