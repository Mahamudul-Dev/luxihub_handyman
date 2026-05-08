import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/contract_type_selector.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/skill_chip_input.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_event.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_state.dart';

class RegistrationDetailsPage extends StatefulWidget {
  const RegistrationDetailsPage({super.key});

  @override
  State<RegistrationDetailsPage> createState() =>
      _RegistrationDetailsPageState();
}

class _RegistrationDetailsPageState extends State<RegistrationDetailsPage> {
  late final ProfileBloc _profileBloc;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedContractType;
  List<String> _skills = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _profileBloc.add(ProfileFetchRequested(authState.user.id));
      }
    });
  }

  @override
  void dispose() {
    _profileBloc.close();
    _nameController.dispose();
    _addressController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  void _prefillFrom(Profile profile) {
    if (_nameController.text.isEmpty && profile.name.isNotEmpty) {
      _nameController.text = profile.name;
    }
    if (_addressController.text.isEmpty && profile.serviceArea != null) {
      _addressController.text = profile.serviceArea!;
    }
    if (_hourlyRateController.text.isEmpty && profile.hourlyRate != null) {
      _hourlyRateController.text = profile.hourlyRate!.toString();
    }
    if (_selectedDate == null && profile.dob != null) {
      _selectedDate = DateTime.tryParse(profile.dob!);
    }
    if (_selectedContractType == null && profile.contractType != null) {
      _selectedContractType = profile.contractType;
    }
    if (_skills.isEmpty && profile.skills.isNotEmpty) {
      _skills = List.from(profile.skills);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 25),
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

  void _onContinue() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    final existing = _profileBloc.state is ProfileLoaded
        ? (_profileBloc.state as ProfileLoaded).profile
        : null;

    setState(() => _isSaving = true);
    _profileBloc.add(ProfileUpdateRequested(Profile(
      id: authState.user.id,
      name: name,
      phone: existing?.phone,
      email: existing?.email,
      dob: _selectedDate?.toIso8601String(),
      contractType: _selectedContractType,
      hourlyRate: double.tryParse(_hourlyRateController.text.trim()),
      serviceArea: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : existing?.serviceArea,
      serviceLat: existing?.serviceLat,
      serviceLng: existing?.serviceLng,
      serviceRadiusKm: existing?.serviceRadiusKm,
      avatarPath: existing?.avatarPath,
      isOnline: existing?.isOnline ?? false,
      isKycVerified: existing?.isKycVerified ?? false,
      skills: _skills,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _profileBloc,
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && !_isSaving) {
            // Initial fetch — pre-fill fields
            _prefillFrom(state.profile);
          }
          if (state is ProfileLoaded && _isSaving) {
            setState(() => _isSaving = false);
            context.push(AppRoutes.registrationServiceArea.path);
          }
          if (state is ProfileError && _isSaving) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = _isSaving || state is ProfileLoading;

          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RegistrationStepIndicator(
                        currentStep: 4, totalSteps: 8),
                    SizedBox(height: 32.h),

                    Text('Your Details',
                        style: AppTextStyles.headlineMedium),
                    SizedBox(height: 6.h),
                    Text(
                      'Fill in your profile information to continue.',
                      style: AppTextStyles.bodyMedium,
                    ),

                    SizedBox(height: 32.h),

                    // ── Full name ───────────────────────────────────────
                    TextFormField(
                      controller: _nameController,
                      style: AppTextStyles.inputText,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        prefixIcon:
                            Icon(Icons.person_outline_rounded, size: 20.r),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // ── Service area / address ──────────────────────────
                    TextFormField(
                      controller: _addressController,
                      style: AppTextStyles.inputText,
                      decoration: InputDecoration(
                        hintText: 'Full Address / Area',
                        prefixIcon: Icon(Icons.home_outlined, size: 20.r),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // ── Date of birth ───────────────────────────────────
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: 'Date of Birth',
                            prefixIcon:
                                Icon(Icons.cake_outlined, size: 20.r),
                            suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 18.r),
                            labelText: _selectedDate != null
                                ? _formattedDate
                                : null,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // ── Area of skills ──────────────────────────────────
                    SkillChipInput(
                      label: 'Area of Skills',
                      hintText:
                          'e.g. Plumbing, Electrical — press Enter to add',
                      initialSkills: _skills,
                      onChanged: (updated) =>
                          setState(() => _skills = updated),
                    ),

                    SizedBox(height: 24.h),

                    // ── Contract type ───────────────────────────────────
                    Text('Contract Type', style: AppTextStyles.bodySmall),
                    SizedBox(height: 8.h),
                    ContractTypeSelector(
                      selectedType: _selectedContractType,
                      onChanged: (value) =>
                          setState(() => _selectedContractType = value),
                    ),

                    SizedBox(height: 24.h),

                    // ── Hourly rate ─────────────────────────────────────
                    TextFormField(
                      controller: _hourlyRateController,
                      style: AppTextStyles.inputText,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Hourly Rate',
                        prefixIcon: Icon(Icons.euro, size: 20.r),
                        suffixText: '/ hr',
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // ── Continue button ─────────────────────────────────
                    ElevatedButton(
                      onPressed: isLoading ? null : _onContinue,
                      child: isLoading
                          ? SizedBox(
                              height: 20.r,
                              width: 20.r,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Continue'),
                    ),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
