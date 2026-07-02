import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener(_onAnimationStatus);
    _startPhase(_BreathingPhase.inhale);
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

  void _finish() {
    if (_finished) return;
    _finished = true;
    _holdTimer?.cancel();
    _controller.stop();
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
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
