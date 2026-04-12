import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class SkillChipInput extends StatefulWidget {
  const SkillChipInput({
    super.key,
    this.initialSkills = const [],
    this.onChanged,
    this.label = 'Area of Skills',
    this.hintText = 'Type a skill and press Enter',
  });

  final List<String> initialSkills;
  final ValueChanged<List<String>>? onChanged;
  final String label;
  final String hintText;

  @override
  State<SkillChipInput> createState() => _SkillChipInputState();
}

class _SkillChipInputState extends State<SkillChipInput> {
  final TextEditingController _controller = TextEditingController();
  late List<String> _skills;

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.initialSkills);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSkill(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !_skills.contains(trimmed)) {
      setState(() => _skills.add(trimmed));
      _controller.clear();
      widget.onChanged?.call(List.unmodifiable(_skills));
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
    widget.onChanged?.call(List.unmodifiable(_skills));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.bodySmall),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_skills.isNotEmpty) ...[
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: _skills.map((skill) {
                    return Chip(
                      label: Text(skill, style: AppTextStyles.bodySmall),
                      deleteIcon: Icon(Icons.close, size: 14.r),
                      onDeleted: () => _removeSkill(skill),
                      backgroundColor: AppColors.splashBackground,
                      side: const BorderSide(color: AppColors.primaryLight),
                      labelPadding: EdgeInsets.symmetric(horizontal: 2.w),
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                SizedBox(height: 8.h),
              ],
              TextField(
                controller: _controller,
                style: AppTextStyles.inputText,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppTextStyles.inputHint,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 2.h),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: _addSkill,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
