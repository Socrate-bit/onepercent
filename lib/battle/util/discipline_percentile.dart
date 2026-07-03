import 'dart:math' as math;

/// Estimates where a user's discipline win-rate places them within the general
/// population, expressed as a percentile (0–100): "you are more disciplined
/// than X% of people".
///
/// ## Empirical basis
/// The reference distribution comes from research on real-world self-control.
/// In Hofmann, Baumeister & Vohs's large "everyday temptations" experience-
/// sampling study (≈205 adults, ≈7,800 logged desire episodes), people who
/// actively tried to resist a desire succeeded on roughly **83%** of occasions,
/// failing about 17% of the time. That 83% is the population *mean* success
/// rate we anchor to ([_populationMean]).
///
/// Individual self-control scores across large samples are close to normally
/// distributed (e.g. the Brief Self-Control Scale shows only minor departures
/// from normality), so we model the population's success rate as a normal
/// distribution and read the percentile off its cumulative curve.
///
/// The spread ([_populationSd]) is a calibrated central estimate rather than a
/// single canonical published figure — tune it here if a better reference
/// sample is adopted. Norms come mostly from student / general-adult samples,
/// so this is a reasonable baseline, not a perfect fit for every population.
class DisciplinePercentile {
  DisciplinePercentile._();

  /// Population mean success rate on resisted temptations (Hofmann et al.).
  static const double _populationMean = 0.83;

  /// Estimated standard deviation of individual success rates. Chosen so the
  /// curve stays sensible across the full 0–100% win-rate range (e.g. a perfect
  /// record lands around the top ~10%, not implausibly higher).
  static const double _populationSd = 0.12;

  /// Bayesian prior strength: how many "population-average" battles to blend in
  /// before trusting the user's raw rate. Prevents a lucky 3-for-3 from reading
  /// as elite; its influence fades as real battles accumulate.
  static const double _priorStrength = 5;

  /// Below this many battles a percentile isn't meaningful yet.
  static const int minBattles = 3;

  /// Population percentile (0–100) for a user with [wins] out of [total]
  /// battles, or null when there isn't enough data yet ([total] < [minBattles]).
  ///
  /// A percentile of 88 means "more disciplined than 88% of people".
  static double? forRecord(int wins, int total) {
    if (total < minBattles || wins < 0 || wins > total) return null;

    // Shrink the observed rate toward the population mean (Bayesian smoothing)
    // so sparse records regress to average instead of hitting the extremes.
    final smoothedRate =
        (wins + _priorStrength * _populationMean) / (total + _priorStrength);

    final z = (smoothedRate - _populationMean) / _populationSd;
    final pct = _standardNormalCdf(z) * 100;
    return pct.clamp(0.1, 99.9);
  }

  /// Standard normal CDF Φ(z), via the erf approximation (Abramowitz & Stegun
  /// 7.1.26, max error ≈ 1.5e-7 — far tighter than we need here).
  static double _standardNormalCdf(double z) =>
      0.5 * (1 + _erf(z / math.sqrt2));

  static double _erf(double x) {
    final sign = x < 0 ? -1.0 : 1.0;
    final ax = x.abs();
    const p = 0.3275911;
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    final t = 1 / (1 + p * ax);
    final y = 1 -
        (((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t) *
            math.exp(-ax * ax);
    return sign * y;
  }
}
