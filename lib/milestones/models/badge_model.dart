class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String quote;
  final BadgeKind kind;

  /// For streak badges: required consecutive days.
  final int? requiredDays;

  /// Display number/label rendered on the hex badge.
  final String displayValue;

  bool earned;
  DateTime? earnedDate;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.quote,
    required this.kind,
    this.requiredDays,
    this.displayValue = '?',
    this.earned = false,
    this.earnedDate,
  });

  BadgeModel copyWith({bool? earned, DateTime? earnedDate}) => BadgeModel(
        id: id,
        name: name,
        description: description,
        quote: quote,
        kind: kind,
        requiredDays: requiredDays,
        displayValue: displayValue,
        earned: earned ?? this.earned,
        earnedDate: earnedDate ?? this.earnedDate,
      );
}

enum BadgeKind { streak, achievement }

/// Streak-tier badges: unlocked automatically when the streak reaches N days.
List<BadgeModel> buildStreakBadges() => [
      BadgeModel(
        id: 'challenge_streak_1',
        name: 'Streak 1',
        description: '1 day streak',
        quote: 'Every journey starts with one step.',
        kind: BadgeKind.streak,
        requiredDays: 1,
        displayValue: '1',
      ),
      BadgeModel(
        id: 'challenge_streak_3',
        name: 'Streak 3',
        description: '3 day streak',
        quote: 'Three in a row. Momentum building.',
        kind: BadgeKind.streak,
        requiredDays: 3,
        displayValue: '3',
      ),
      BadgeModel(
        id: 'challenge_streak_7',
        name: 'Streak 7',
        description: '7 day streak',
        quote: 'A full week. You are forming a habit.',
        kind: BadgeKind.streak,
        requiredDays: 7,
        displayValue: '7',
      ),
      BadgeModel(
        id: 'challenge_streak_14',
        name: 'Streak 14',
        description: '14 day streak',
        quote: 'Two weeks. The habit is sticking.',
        kind: BadgeKind.streak,
        requiredDays: 14,
        displayValue: '14',
      ),
      BadgeModel(
        id: 'challenge_streak_30',
        name: 'Streak 30',
        description: '30 day streak',
        quote: 'A full month. Unstoppable.',
        kind: BadgeKind.streak,
        requiredDays: 30,
        displayValue: '30',
      ),
      BadgeModel(
        id: 'challenge_streak_100',
        name: 'Streak 100',
        description: '100 day streak',
        quote: 'One hundred days. A new you.',
        kind: BadgeKind.streak,
        requiredDays: 100,
        displayValue: '100',
      ),
      BadgeModel(
        id: 'challenge_streak_365',
        name: 'Streak 365',
        description: '365 day streak',
        quote: 'A full year. Legendary.',
        kind: BadgeKind.streak,
        requiredDays: 365,
        displayValue: '365',
      ),
    ];

/// Placeholder achievement badges. Define your own per-project conditions in
/// [StreakService.onActivityCompleted] — the stubs below currently never unlock.
List<BadgeModel> buildAchievementBadges() => [
      BadgeModel(
        id: 'challenge_1',
        name: 'Challenge 1',
        description: 'TODO: define condition',
        quote: 'Replace with your own challenge copy.',
        kind: BadgeKind.achievement,
        displayValue: '1',
      ),
      BadgeModel(
        id: 'challenge_2',
        name: 'Challenge 2',
        description: 'TODO: define condition',
        quote: 'Replace with your own challenge copy.',
        kind: BadgeKind.achievement,
        displayValue: '2',
      ),
      BadgeModel(
        id: 'challenge_3',
        name: 'Challenge 3',
        description: 'TODO: define condition',
        quote: 'Replace with your own challenge copy.',
        kind: BadgeKind.achievement,
        displayValue: '3',
      ),
    ];
