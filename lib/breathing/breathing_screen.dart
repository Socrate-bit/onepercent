import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Looping ambient music played behind the breathing exercise.
const _breathingMusicUrl =
    'https://firebasestorage.googleapis.com/v0/b/levio-ef67e.firebasestorage.app/o/meditation_sound.mp3?alt=media&token=325c4a8e-3862-468b-b331-e6fa3a9367f7';

/// Bounds for the round stepper in the setup sheet.
const _minRounds = 1;
const _maxRounds = 20;
const _defaultRounds = 5;

/// Breathing accent used across the exercise and its setup sheet.
const _breathingAccent = Color(0xFF5AA9FF);

/// Asks the user how many breathing rounds they want via a modal bottom sheet,
/// then returns the chosen count — or `null` if they dismiss without starting.
Future<int?> showBreathingSetupDialog(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _BreathingSetupSheet(),
  );
}

class _BreathingSetupSheet extends StatefulWidget {
  const _BreathingSetupSheet();

  @override
  State<_BreathingSetupSheet> createState() => _BreathingSetupSheetState();
}

class _BreathingSetupSheetState extends State<_BreathingSetupSheet> {
  int _rounds = _defaultRounds;

  void _step(int delta) {
    final next = (_rounds + delta).clamp(_minRounds, _maxRounds);
    if (next == _rounds) return;
    HapticFeedback.selectionClick();
    setState(() => _rounds = next);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'BREATHING',
              style: TextStyle(
                color: _breathingAccent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'How many rounds?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: _rounds > _minRounds ? () => _step(-1) : null,
                ),
                SizedBox(
                  width: 96,
                  child: Text(
                    '$_rounds',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: _rounds < _maxRounds ? () => _step(1) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'rounds',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_rounds),
              style: FilledButton.styleFrom(
                backgroundColor: _breathingAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'START',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: AppColors.background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(
            icon,
            size: 28,
            color: enabled ? _breathingAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

enum _BreathingPhase { inhale, holdIn, exhale, holdOut }

/// Standalone guided box-breathing exercise. An inner circle grows on inhale,
/// holds at max, shrinks on exhale, and holds at min — repeated [rounds] times.
///
/// Adapted from a mission-based breathing screen: alarm coupling, localization,
/// and responsive-sizing dependencies were removed so it stands alone.
class BreathingScreen extends StatefulWidget {
  final int inhaleDurationMs;
  final int holdAfterInhaleDurationMs;
  final int exhaleDurationMs;
  final int holdAfterExhaleDurationMs;
  final int rounds;

  const BreathingScreen({
    super.key,
    this.inhaleDurationMs = 4000,
    this.holdAfterInhaleDurationMs = 4000,
    this.exhaleDurationMs = 4000,
    this.holdAfterExhaleDurationMs = 4000,
    this.rounds = 3,
  });

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  _BreathingPhase _phase = _BreathingPhase.inhale;
  int _round = 0;
  Timer? _holdTimer;
  bool _finished = false;
  final _musicPlayer = AudioPlayer();
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener(_onAnimationStatus);
    _startMusic();
    _startPhase(_BreathingPhase.inhale);
  }

  Future<void> _startMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(UrlSource(_breathingMusicUrl));
    } catch (_) {
      // Music is a non-essential enhancement; ignore playback failures.
    }
  }

  Future<void> _toggleMute() async {
    HapticFeedback.selectionClick();
    final next = !_muted;
    await _musicPlayer.setVolume(next ? 0 : 1);
    if (mounted) setState(() => _muted = next);
  }

  void _startPhase(_BreathingPhase phase) {
    if (!mounted || _finished) return;
    setState(() => _phase = phase);
    HapticFeedback.lightImpact();

    switch (phase) {
      case _BreathingPhase.inhale:
        _controller.duration = Duration(milliseconds: widget.inhaleDurationMs);
        _controller.forward(from: 0.0);
        break;
      case _BreathingPhase.exhale:
        _controller.duration = Duration(milliseconds: widget.exhaleDurationMs);
        _controller.reverse(from: 1.0);
        break;
      case _BreathingPhase.holdIn:
        _controller.value = 1.0;
        _holdTimer = Timer(
          Duration(milliseconds: widget.holdAfterInhaleDurationMs),
          _advanceFromHold,
        );
        break;
      case _BreathingPhase.holdOut:
        _controller.value = 0.0;
        _holdTimer = Timer(
          Duration(milliseconds: widget.holdAfterExhaleDurationMs),
          _advanceFromHold,
        );
        break;
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (!mounted || _finished) return;
    if (_phase == _BreathingPhase.inhale &&
        status == AnimationStatus.completed) {
      _startPhase(_BreathingPhase.holdIn);
    } else if (_phase == _BreathingPhase.exhale &&
        status == AnimationStatus.dismissed) {
      _startPhase(_BreathingPhase.holdOut);
    }
  }

  void _advanceFromHold() {
    if (!mounted || _finished) return;
    if (_phase == _BreathingPhase.holdIn) {
      _startPhase(_BreathingPhase.exhale);
    } else if (_phase == _BreathingPhase.holdOut) {
      final next = _round + 1;
      if (next >= widget.rounds) {
        _finish();
        return;
      }
      setState(() => _round = next);
      _startPhase(_BreathingPhase.inhale);
    }
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _holdTimer?.cancel();
    _controller.stop();
    await _musicPlayer.stop();
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  String get _phaseLabel {
    switch (_phase) {
      case _BreathingPhase.inhale:
        return 'Breathe in';
      case _BreathingPhase.exhale:
        return 'Breathe out';
      case _BreathingPhase.holdIn:
      case _BreathingPhase.holdOut:
        return 'Hold';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _phaseLabel,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, _) => CustomPaint(
                        painter: _BreathingPainter(progress: _controller.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Round ${_round + 1} of ${widget.rounds}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Icon(
                  _muted ? Icons.volume_off : Icons.volume_up,
                  color: _muted ? AppColors.textSecondary : _breathingAccent,
                ),
                onPressed: _toggleMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingPainter extends CustomPainter {
  final double progress;
  _BreathingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - 4;
    final minInner = outerRadius * 0.25;
    final maxInner = outerRadius * 0.95;
    final innerRadius = lerpDouble(minInner, maxInner, progress)!;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF5AA9FF).withAlpha(90);
    canvas.drawCircle(center, outerRadius, ringPaint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF5AA9FF).withAlpha(70);
    canvas.drawCircle(center, innerRadius, fillPaint);
  }

  @override
  bool shouldRepaint(_BreathingPainter old) => progress != old.progress;
}
