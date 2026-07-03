import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../models/battle.dart';

/// The outcome of the difficulty sheet: how hard it felt, an optional name
/// describing the decision, whether the user asked to breathe afterwards, and
/// whether they want to jump straight into Recovery mode.
typedef DifficultyResult = ({
  int difficulty,
  String name,
  bool breathe,
  bool recover,
});

/// Presents a modal bottom sheet asking how hard the decision felt on a 0–10
/// scale (plus an optional decision name) before the outcome is committed.
/// Returns the entry, or `null` if the user dismisses without confirming
/// (nothing should be recorded).
Future<DifficultyResult?> showDifficultyDialog(
  BuildContext context,
  BattleOutcome outcome,
) {
  return showModalBottomSheet<DifficultyResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DifficultySheet(outcome: outcome),
  );
}

class _DifficultySheet extends StatefulWidget {
  final BattleOutcome outcome;
  const _DifficultySheet({required this.outcome});

  @override
  State<_DifficultySheet> createState() => _DifficultySheetState();
}

class _DifficultySheetState extends State<_DifficultySheet> {
  double _value = 5;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit({bool breathe = false, bool recover = false}) {
    Navigator.of(context).pop(
      (
        difficulty: _value.round(),
        name: _nameController.text.trim(),
        breathe: breathe,
        recover: recover,
      ),
    );
  }

  /// Loss-only support block: two reflective prompts and a breathe shortcut.
  Widget _reflection(Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _question('Will you be happy to have done that tomorrow?'),
          const SizedBox(height: 12),
          _question('What is the little step you feel to do?'),
          const SizedBox(height: 16),
          _BreatheButton(onTap: () => _submit(breathe: true)),
          const SizedBox(height: 10),
          _RecoveryButton(onTap: () => _submit(recover: true)),
        ],
      ),
    );
  }

  Widget _question(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.self_improvement_rounded,
            color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWin = widget.outcome == BattleOutcome.win;
    final accent = isWin ? AppColors.win : AppColors.loss;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isWin ? 'LOGGING A WIN' : 'LOGGING A LOSS',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'How hard is this one?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '${_value.round()}',
                style: TextStyle(
                  color: accent,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Center(
              child: Text(
                'difficulty (0–10)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: accent,
                inactiveTrackColor: AppColors.cardBorder,
                thumbColor: accent,
                overlayColor: accent.withValues(alpha: 0.2),
                valueIndicatorColor: accent,
              ),
              child: Slider(
                value: _value,
                min: 0,
                max: 10,
                divisions: 10,
                label: '${_value.round()}',
                onChanged: (v) => setState(() => _value = v),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: AppColors.textPrimary),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: 'What was the decision? (optional)',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent),
                ),
              ),
            ),
            if (!isWin) ...[
              const SizedBox(height: 20),
              _reflection(accent),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'CONFIRM',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact "Breathe" call-to-action shown inside the loss reflection block.
class _BreatheButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BreatheButton({required this.onTap});

  static const Color _breathe = Color(0xFF5AA9FF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _breathe.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.air_rounded, color: _breathe, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Take a breath first',
                  style: TextStyle(
                    color: _breathe,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _breathe),
            ],
          ),
        ),
      ),
    );
  }
}

/// A "Go to Recovery mode" call-to-action shown inside the loss reflection
/// block, below the breathe shortcut.
class _RecoveryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecoveryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.win.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.healing_rounded, color: AppColors.win, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Go to Recovery mode',
                  style: TextStyle(
                    color: AppColors.win,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.win),
            ],
          ),
        ),
      ),
    );
  }
}
