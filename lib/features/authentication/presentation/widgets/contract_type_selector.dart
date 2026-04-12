import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class ContractOption {
  const ContractOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class ContractTypeSelector extends StatelessWidget {
  ContractTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final String? selectedType;
  final ValueChanged<String> onChanged;

  final List<ContractOption> _options = [
    const ContractOption(
      value: 'hourly',
      label: 'Hourly',
      icon: Icons.access_time_rounded,
    ),
    const ContractOption(
      value: 'contractual',
      label: 'Contractual',
      icon: Icons.description_outlined,
    ),
    const ContractOption(
      value: 'both',
      label: 'Both',
      icon: Icons.handshake_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_options.length, (index) {
        final option = _options[index];
        final isSelected = selectedType == option.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                right: index < _options.length - 1 ? 8.w : 0,
              ),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.inputFill,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.inputBorder,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 22.r,
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    option.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
