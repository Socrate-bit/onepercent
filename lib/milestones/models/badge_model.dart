class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String quote;
  final BadgeKind kind;

  // For streak badges: required days
  final int? requiredDays;

  // For achievement badges: display number on hex
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

List<BadgeModel> buildStreakBadges() => [
      BadgeModel(
        id: 'risen',
        name: 'Risen',
        description: '1 day',
        quote: 'The journey of a thousand mornings begins with one alarm.',
        kind: BadgeKind.streak,
        requiredDays: 1,
        displayValue: '1',
      ),
      BadgeModel(
        id: 'ignite',
        name: 'Ignite',
        description: '3 days',
        quote: 'Three days in. The flame is growing.',
        kind: BadgeKind.streak,
        requiredDays: 3,
        displayValue: '3',
      ),
      BadgeModel(
        id: 'horizon',
        name: 'Horizon',
        description: '7 days',
        quote: 'A week of mornings — you\'re rewriting your story.',
        kind: BadgeKind.streak,
        requiredDays: 7,
        displayValue: '7',
      ),
      BadgeModel(
        id: 'aurora',
        name: 'Aurora',
        description: '14 days',
        quote: 'Two weeks of sunrise. Keep chasing the light.',
        kind: BadgeKind.streak,
        requiredDays: 14,
        displayValue: '14',
      ),
      BadgeModel(
        id: 'celestial',
        name: 'Celestial',
        description: '30 days',
        quote: 'A full month of rising. You are unstoppable.',
        kind: BadgeKind.streak,
        requiredDays: 30,
        displayValue: '30',
      ),
      BadgeModel(
        id: 'nebula',
        name: 'Nebula',
        description: '100 days',
        quote: 'One hundred mornings. A new you has been born.',
        kind: BadgeKind.streak,
        requiredDays: 100,
        displayValue: '100',
      ),
      BadgeModel(
        id: 'eternal',
        name: 'Eternal',
        description: '365 days',
        quote: 'A full year of mornings. You are legendary.',
        kind: BadgeKind.streak,
        requiredDays: 365,
        displayValue: '365',
      ),
    ];

List<BadgeModel> buildAchievementBadges() => [
      BadgeModel(
        id: 'versatile',
        name: 'Versatile',
        description: 'Use all 13 mission types',
        quote: 'Mastery comes from variety.',
        kind: BadgeKind.achievement,
        displayValue: '13',
      ),
      BadgeModel(
        id: 'first_light',
        name: 'First Light',
        description: 'Wake up before 5:30 AM',
        quote: 'The early bird catches the sunrise.',
        kind: BadgeKind.achievement,
        displayValue: '?',
      ),
      BadgeModel(
        id: 'blitz',
        name: 'Blitz',
        description: 'Turn off alarm in under 15s',
        quote: 'Speed of light. Speed of life.',
        kind: BadgeKind.achievement,
        displayValue: '<15s',
      ),
      BadgeModel(
        id: 'no_days_off',
        name: 'No Days Off',
        description: '30 consecutive wakeups',
        quote: 'Weekends are just weekdays in disguise.',
        kind: BadgeKind.achievement,
        displayValue: '30',
      ),
      BadgeModel(
        id: 'converted',
        name: 'Converted',
        description: 'Reach a 7-day streak',
        quote: 'Even night owls can learn to love the dawn.',
        kind: BadgeKind.achievement,
        displayValue: '7',
      ),
      BadgeModel(
        id: 'audiophile',
        name: 'Audiophile',
        description: 'Use 4+ different alarm sounds',
        quote: 'Every morning deserves its own soundtrack.',
        kind: BadgeKind.achievement,
        displayValue: '4+',
      ),
    ];

/// Sleep (bedtime) achievement badges — unlocked only by completing sleep
/// alarms, mirroring the wake-up achievement set. Display copy is localized via
/// l10n_helpers; the strings here are English fallbacks.
List<BadgeModel> buildSleepAchievementBadges() => [
      BadgeModel(
        id: 'first_night',
        name: 'First Night',
        description: 'Complete your first wind-down',
        quote: 'Every good morning begins the night before.',
        kind: BadgeKind.achievement,
        displayValue: '1',
      ),
      BadgeModel(
        id: 'early_to_bed',
        name: 'Early to Bed',
        description: 'Wind down before 10 PM',
        quote: 'Rest is the foundation the day is built on.',
        kind: BadgeKind.achievement,
        displayValue: '🌙',
      ),
      BadgeModel(
        id: 'calm_mind',
        name: 'Calm Mind',
        description: 'Finish a meditation or breathing wind-down',
        quote: 'A quiet mind sleeps deepest.',
        kind: BadgeKind.achievement,
        displayValue: '🧘',
      ),
      BadgeModel(
        id: 'dreamer',
        name: 'Dreamer',
        description: 'Use all 6 wind-down missions',
        quote: 'There is more than one path to a good night.',
        kind: BadgeKind.achievement,
        displayValue: '6',
      ),
      BadgeModel(
        id: 'well_rested',
        name: 'Well Rested',
        description: 'Reach a 7-day streak on a sleep alarm',
        quote: 'Seven nights of intention. Sleep becomes a ritual.',
        kind: BadgeKind.achievement,
        displayValue: '7',
      ),
      BadgeModel(
        id: 'no_nights_off',
        name: 'No Nights Off',
        description: '30 consecutive nights of winding down',
        quote: 'Consistency is the quietest superpower.',
        kind: BadgeKind.achievement,
        displayValue: '30',
      ),
    ];
