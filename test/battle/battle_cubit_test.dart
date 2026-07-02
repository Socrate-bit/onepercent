import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepercent/battle/cubit/battle_cubit.dart';
import 'package:onepercent/battle/cubit/battle_state.dart';
import 'package:onepercent/battle/models/battle.dart';
import 'package:onepercent/battle/services/battle_service.dart';

class MockBattleService extends Mock implements BattleService {}

const uid = 'user-1';

Battle _b(BattleOutcome outcome, int day) => Battle(
      id: '$outcome-$day',
      outcome: outcome,
      ts: DateTime(2026, 1, day, 12),
    );

void main() {
  late MockBattleService service;

  setUpAll(() {
    registerFallbackValue(BattleOutcome.win);
  });

  setUp(() {
    service = MockBattleService();
    when(() => service.addBattle(any(), any())).thenAnswer((_) async {});
  });

  test('emits battles from the service stream and clears loading', () async {
    when(() => service.watchBattles(uid)).thenAnswer(
      (_) => Stream.value([_b(BattleOutcome.win, 1), _b(BattleOutcome.win, 2)]),
    );

    final cubit = BattleCubit(service: service, uid: uid);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.battles.length, 2);
    expect(cubit.state.currentStreak, 2);
    await cubit.close();
  });

  test('recordWin and recordLoss delegate to the service', () async {
    when(() => service.watchBattles(uid))
        .thenAnswer((_) => const Stream.empty());
    final cubit = BattleCubit(service: service, uid: uid);

    await cubit.recordWin();
    await cubit.recordLoss();

    verify(() => service.addBattle(uid, BattleOutcome.win)).called(1);
    verify(() => service.addBattle(uid, BattleOutcome.loss)).called(1);
    await cubit.close();
  });

  test('setRange updates the state window', () async {
    when(() => service.watchBattles(uid))
        .thenAnswer((_) => const Stream.empty());
    final cubit = BattleCubit(service: service, uid: uid);

    cubit.setRange(StatsRange.last7);
    expect(cubit.state.range, StatsRange.last7);
    await cubit.close();
  });

  test('surfaces an error when the stream fails', () async {
    when(() => service.watchBattles(uid))
        .thenAnswer((_) => Stream.error(Exception('boom')));
    final cubit = BattleCubit(service: service, uid: uid);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.error, isNotNull);
    await cubit.close();
  });

  test('sets an error message when a write fails', () async {
    when(() => service.watchBattles(uid))
        .thenAnswer((_) => const Stream.empty());
    when(() => service.addBattle(any(), any()))
        .thenThrow(Exception('offline'));
    final cubit = BattleCubit(service: service, uid: uid);

    await cubit.recordWin();
    expect(cubit.state.error, isNotNull);
    await cubit.close();
  });
}
