import '../../battle/models/battle.dart';

/// A single progressive streak milestone. Badges unlock off the user's
/// best-ever win streak, so once earned they are permanent — a later loss
/// never revokes one.
class StreakBadge {
  final String id;
  final String name;

  /// Consecutive wins required to unlock this badge.
  final int requiredDays;

  /// Short line shown on the unlock/detail screen.
  final String quote;

  /// Whether the user's best streak has reached [requiredDays].
  bool earned;

  /// The day the running streak first crossed [requiredDays], if it ever did.
  DateTime? earnedDate;

  StreakBadge({
    required this.id,
    required this.name,
    required this.requiredDays,
    required this.quote,
    this.earned = false,
    this.earnedDate,
  });
}

/// The 10 progressive streak milestones, ascending by requirement. Edit the
/// requirements/names/quotes here — everything else derives from this list.
List<StreakBadge> _defs() => [
      StreakBadge(
        id: 'spark',
        name: 'Spark',
        requiredDays: 1,
        quote: 'Every fire starts with a single spark.',
      ),
      StreakBadge(
        id: 'ember',
        name: 'Ember',
        requiredDays: 3,
        quote: 'Three wins in. The ember glows.',
      ),
      StreakBadge(
        id: 'flame',
        name: 'Flame',
        requiredDays: 7,
        quote: 'A full week of discipline. The flame takes hold.',
      ),
      StreakBadge(
        id: 'blaze',
        name: 'Blaze',
        requiredDays: 14,
        quote: 'Two weeks strong — you are burning bright.',
      ),
      StreakBadge(
        id: 'forge',
        name: 'Forge',
        requiredDays: 30,
        quote: 'A month of wins. You are forging a new self.',
      ),
      StreakBadge(
        id: 'inferno',
        name: 'Inferno',
        requiredDays: 100,
        quote: 'One hundred wins. Unstoppable.',
      ),
      StreakBadge(
        id: 'wildfire',
        name: 'Wildfire',
        requiredDays: 300,
        quote: 'Three hundred wins. Nothing contains you now.',
      ),
      StreakBadge(
        id: 'phoenix',
        name: 'Phoenix',
        requiredDays: 1000,
        quote: 'A thousand wins. You have risen, reborn.',
      ),
      StreakBadge(
        id: 'titan',
        name: 'Titan',
        requiredDays: 3000,
        quote: 'Three thousand wins. The discipline of a titan.',
      ),
      StreakBadge(
        id: 'immortal',
        name: 'Immortal',
        requiredDays: 10000,
        quote: 'Ten thousand wins. Legend made flesh.',
      ),
    ];

/// Builds the badge list and marks each earned/unlocked against [battles].
///
/// Walks battles oldest-first tracking a running win streak (reset on loss,
/// matching [Battle] semantics), stamping each badge's [StreakBadge.earnedDate]
/// the moment the running streak first reaches its requirement. A badge stays
/// earned even if the streak later breaks, because the threshold was met.
List<StreakBadge> evaluateStreakBadges(List<Battle> battles) {
  final badges = _defs();

  // Oldest first — Battle stream is emitted oldest-first, but sort defensively.
  final ordered = [...battles]..sort((a, b) => a.ts.compareTo(b.ts));

  var run = 0;
  for (final b in ordered) {
    if (b.isWin) {
      run++;
      for (final badge in badges) {
        if (!badge.earned && run >= badge.requiredDays) {
          badge.earned = true;
          badge.earnedDate = b.ts;
        }
      }
    } else {
      run = 0;
    }
  }

  return badges;
}

/// Convenience views over an evaluated badge list.
extension StreakBadgeList on List<StreakBadge> {
  int get earnedCount => where((b) => b.earned).length;

  /// The highest-requirement badge earned so far, or null if none.
  StreakBadge? get highestEarned {
    StreakBadge? best;
    for (final b in this) {
      if (b.earned) best = b;
    }
    return best;
  }

  /// The next badge still to unlock, or null once all are earned.
  StreakBadge? get nextLocked {
    for (final b in this) {
      if (!b.earned) return b;
    }
    return null;
  }
}
