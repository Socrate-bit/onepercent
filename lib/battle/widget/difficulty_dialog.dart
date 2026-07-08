import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';
import '../models/battle.dart';

/// The outcome of the difficulty sheet: how hard it felt, an optional name
/// describing the decision, the personal values tagged onto it, whether the
/// user asked to breathe afterwards, and whether they want to jump straight
/// into Recovery mode.
typedef DifficultyResult = ({
  int difficulty,
  String name,
  List<String> values,
  bool socialExpansion,
  bool breathe,
  bool recover,
});

/// Presents a modal bottom sheet asking how hard the decision felt on a 0–10
/// scale (plus an optional decision name and value tags) before the outcome is
/// committed. [values] are the user's ranked value titles offered as tags.
/// [onAddValue], when provided, powers an "Add value" chip: it should create a
/// value and return its title (or null if cancelled), which is then tagged.
/// Returns the entry, or `null` if the user dismisses without confirming
/// (nothing should be recorded).
Future<DifficultyResult?> showDifficultyDialog(
  BuildContext context,
  BattleOutcome outcome, {
  List<String> values = const [],
  Future<String?> Function()? onAddValue,
}) {
  return showModalBottomSheet<DifficultyResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DifficultySheet(
      outcome: outcome,
      values: values,
      onAddValue: onAddValue,
    ),
  );
}

class _DifficultySheet extends StatefulWidget {
  final BattleOutcome outcome;
  final List<String> values;
  final Future<String?> Function()? onAddValue;
  const _DifficultySheet({
    required this.outcome,
    required this.values,
    this.onAddValue,
  });

  @override
  State<_DifficultySheet> createState() => _DifficultySheetState();
}

class _DifficultySheetState extends State<_DifficultySheet> {
  double _value = 5;
  final _nameController = TextEditingController();
  final Set<String> _selectedValues = {};
  bool _socialExpansion = false;

  /// Mutable copy of the offered values so a freshly-added one shows instantly.
  late final List<String> _values = [...widget.values];

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
        values: _selectedValues.toList(),
        socialExpansion: _socialExpansion,
        breathe: breathe,
        recover: recover,
      ),
    );
  }

  /// Opens the caller-provided add-value flow, then tags the new value.
  Future<void> _addValue() async {
    final added = (await widget.onAddValue?.call())?.trim();
    if (added == null || added.isEmpty || !mounted) return;
    setState(() {
      if (!_values.contains(added)) _values.add(added);
      _selectedValues.add(added);
    });
  }

  /// Multi-select value tags. Shown when the user has values to offer or an
  /// [onAddValue] hook is available (so an empty list still gets an add chip).
  Widget _valuePicker(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TAG YOUR VALUES (optional)',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5.sp,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final value in _values)
              _ValueChip(
                label: value,
                selected: _selectedValues.contains(value),
                accent: accent,
                onTap: () => setState(() {
                  if (!_selectedValues.remove(value)) {
                    _selectedValues.add(value);
                  }
                }),
              ),
            if (widget.onAddValue != null)
              _AddValueChip(accent: accent, onTap: _addValue),
          ],
        ),
      ],
    );
  }

  /// A tappable card tagging the decision as a "social expansion" — putting
  /// yourself out there socially. Available on both wins and losses.
  Widget _socialExpansionToggle() {
    const accent = AppColors.social;
    final selected = _socialExpansion;
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : AppColors.background,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () => setState(() => _socialExpansion = !_socialExpansion),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected ? accent : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.groups_rounded, color: accent, size: 22.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Social expansion',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'You put yourself out there socially',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? accent : AppColors.textSecondary,
                size: 22.r,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Loss-only support block: two reflective prompts and a breathe shortcut.
  Widget _reflection(Color accent) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _question('Will you be happy to have done that tomorrow?'),
          SizedBox(height: 12.h),
          _question('What is the little step you feel to do?'),
          SizedBox(height: 16.h),
          _BreatheButton(onTap: () => _submit(breathe: true)),
          SizedBox(height: 10.h),
          _RecoveryButton(onTap: () => _submit(recover: true)),
        ],
      ),
    );
  }

  Widget _question(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.self_improvement_rounded,
            color: AppColors.textSecondary, size: 18.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
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
        // Cap the sheet height so tall content (values, social tag, loss
        // reflection) scrolls instead of overflowing the screen.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.fromLTRB(
          24.w,
          12.h,
          24.w,
          24.h + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: const Border(top: BorderSide(color: AppColors.cardBorder)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Grab handle.
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(
              isWin ? 'LOGGING A WIN' : 'LOGGING A LOSS',
              style: TextStyle(
                color: accent,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'How hard is this one?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 20.h),
            Center(
              child: Text(
                '${_value.round()}',
                style: TextStyle(
                  color: accent,
                  fontSize: 52.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Center(
              child: Text(
                'difficulty (0–10)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
              ),
            ),
            SizedBox(height: 8.h),
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
            SizedBox(height: 16.h),
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
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: accent),
                ),
              ),
            ),
            if (_values.isNotEmpty || widget.onAddValue != null) ...[
              SizedBox(height: 18.h),
              _valuePicker(accent),
            ],
            SizedBox(height: 18.h),
            _socialExpansionToggle(),
            if (!isWin) ...[
              SizedBox(height: 20.h),
              _reflection(accent),
            ],
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
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
      ),
    );
  }
}

/// A toggleable value tag. Filled with the outcome accent when selected,
/// otherwise a plain outlined chip.
class _ValueChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _ValueChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.18) : AppColors.background,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected ? accent : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 16.r,
                color: selected ? accent : AppColors.textSecondary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: selected ? accent : AppColors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dashed-feel "Add value" chip that opens the add-value flow. Lets users
/// create a value on the spot when they have none (or want a new one).
class _AddValueChip extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  const _AddValueChip({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16.r, color: accent),
              SizedBox(width: 6.w),
              Text(
                'Add value',
                style: TextStyle(
                  color: accent,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(Icons.air_rounded, color: _breathe, size: 22.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Take a breath first',
                  style: TextStyle(
                    color: _breathe,
                    fontSize: 14.sp,
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
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(Icons.healing_rounded, color: AppColors.win, size: 22.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Go to Recovery mode',
                  style: TextStyle(
                    color: AppColors.win,
                    fontSize: 14.sp,
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
