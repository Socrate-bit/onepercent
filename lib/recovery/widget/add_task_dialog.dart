import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';

/// Presents a modal bottom sheet to add a recovery task. Returns the trimmed
/// title, or `null` if the user dismisses without confirming. Tapping one of
/// the [presets] chips returns that title immediately.
Future<String?> showAddTaskDialog(
  BuildContext context, {
  List<String> presets = const [],
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTaskSheet(presets: presets),
  );
}

class _AddTaskSheet extends StatefulWidget {
  final List<String> presets;
  const _AddTaskSheet({required this.presets});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.fire;

    return SafeArea(
      top: false,
      child: Container(
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
              'RECOVERY TASK',
              style: TextStyle(
                color: accent,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'What small step will get you back?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: AppColors.textPrimary),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: 'e.g. Drink a glass of water',
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
                  borderSide: const BorderSide(color: accent),
                ),
              ),
            ),
            if (widget.presets.isNotEmpty) ...[
              SizedBox(height: 18.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'QUICK ADD',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5.sp,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final preset in widget.presets)
                    _PresetChip(
                      label: preset,
                      onTap: () => Navigator.of(context).pop(preset),
                    ),
                ],
              ),
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
                      'ADD TASK',
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

/// A tappable suggestion chip that adds its [label] as a task on tap.
class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16.r, color: AppColors.fire),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
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
