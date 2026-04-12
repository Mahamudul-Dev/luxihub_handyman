import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/contract_type_selector.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/skill_chip_input.dart';

class RegistrationDetailsPage extends StatefulWidget {
  const RegistrationDetailsPage({super.key});

  @override
  State<RegistrationDetailsPage> createState() =>
      _RegistrationDetailsPageState();
}

class _RegistrationDetailsPageState extends State<RegistrationDetailsPage> {
  DateTime? _selectedDate;
  String? _selectedContractType;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18),
      helpText: 'Select Date of Birth',
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String get _formattedDate {
    if (_selectedDate == null) return '';
    return '${_selectedDate!.day.toString().padLeft(2, '0')} / '
        '${_selectedDate!.month.toString().padLeft(2, '0')} / '
        '${_selectedDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RegistrationStepIndicator(currentStep: 4, totalSteps: 8),
              SizedBox(height: 32.h),

              // ── Heading ───────────────────────────────────────────────────
              Text('Your Details', style: AppTextStyles.headlineMedium),
              SizedBox(height: 6.h),
              Text(
                'Fill in your profile information to continue.',
                style: AppTextStyles.bodyMedium,
              ),

              SizedBox(height: 32.h),

              // ── Full name ─────────────────────────────────────────────────
              TextFormField(
                style: AppTextStyles.inputText,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20.r),
                ),
              ),

              SizedBox(height: 16.h),

              // ── Full address ──────────────────────────────────────────────
              TextFormField(
                style: AppTextStyles.inputText,
                decoration: InputDecoration(
                  hintText: 'Full Address',
                  prefixIcon: Icon(Icons.home_outlined, size: 20.r),
                ),
              ),

              SizedBox(height: 16.h),

              // ── Date of birth ─────────────────────────────────────────────
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Date of Birth',
                      prefixIcon: Icon(Icons.cake_outlined, size: 20.r),
                      suffixIcon:
                          Icon(Icons.calendar_today_outlined, size: 18.r),
                      labelText:
                          _selectedDate != null ? _formattedDate : null,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // ── Area of skills ────────────────────────────────────────────
              const SkillChipInput(
                label: 'Area of Skills',
                hintText: 'e.g. Plumbing, Electrical — press Enter to add',
              ),

              SizedBox(height: 24.h),

              // ── Contract type ─────────────────────────────────────────────
              Text('Contract Type', style: AppTextStyles.bodySmall),
              SizedBox(height: 8.h),
              ContractTypeSelector(
                selectedType: _selectedContractType,
                onChanged: (value) =>
                    setState(() => _selectedContractType = value),
              ),

              SizedBox(height: 24.h),

              // ── Hourly rate ───────────────────────────────────────────────
              TextFormField(
                style: AppTextStyles.inputText,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Hourly Rate',
                  prefixIcon: Icon(Icons.euro, size: 20.r),
                  suffixText: '/ hr',
                ),
              ),

              SizedBox(height: 32.h),

              // ── Continue button ───────────────────────────────────────────
              ElevatedButton(
                onPressed: () =>
                    context.push(AppRoutes.registrationServiceArea.path),
                child: const Text('Continue'),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
