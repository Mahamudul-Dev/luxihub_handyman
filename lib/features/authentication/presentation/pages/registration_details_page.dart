import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/contract_type_selector.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_event.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // ── Category picker state ────────────────────────────────────────────────
  List<_Category> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>();
    _fetchCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _profileBloc.add(ProfileFetchRequested(authState.user.id));
      }
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await sl<SupabaseClient>()
          .from('categories')
          .select('id, name, image_url')
          .eq('is_active', true)
          .order('sort_order');
      if (mounted) {
        setState(() {
          _categories = (data as List)
              .map((e) => _Category(
                    id: e['id'] as String,
                    name: e['name'] as String,
                    imageUrl: e['image_url'] as String? ?? '',
                  ))
              .toList();
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
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

  void _toggleCategory(String name) {
    setState(() {
      if (_skills.contains(name)) {
        _skills.remove(name);
      } else {
        _skills.add(name);
      }
    });
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

    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill')),
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
            _prefillFrom(state.profile);
            setState(() {});
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

                    // ── Area of Skills ──────────────────────────────────
                    Text('Area of Skills', style: AppTextStyles.bodySmall),
                    SizedBox(height: 4.h),
                    Text(
                      'Select all that apply',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint, fontSize: 11.sp),
                    ),
                    SizedBox(height: 12.h),

                    if (_loadingCategories)
                      const Center(child: CircularProgressIndicator())
                    else if (_categories.isEmpty)
                      Text(
                        'No categories available.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textHint),
                      )
                    else
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: _categories.map((cat) {
                          final selected = _skills.contains(cat.name);
                          return GestureDetector(
                            onTap: () => _toggleCategory(cat.name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.inputBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (cat.imageUrl.isNotEmpty)
                                    Image.network(
                                      cat.imageUrl,
                                      width: 20.r,
                                      height: 20.r,
                                      color: selected
                                          ? AppColors.textOnPrimary
                                          : null,
                                      colorBlendMode: selected
                                          ? BlendMode.srcIn
                                          : null,
                                      errorBuilder: (_, _, _) =>
                                          Icon(Icons.build_outlined,
                                              size: 18.r,
                                              color: selected
                                                  ? AppColors.textOnPrimary
                                                  : AppColors.textSecondary),
                                    ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    cat.name,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? AppColors.textOnPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
                        prefixIcon:
                            Icon(Icons.currency_pound_rounded, size: 20.r),
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
                                  strokeWidth: 2,
                                  color: Colors.white),
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

class _Category {
  final String id;
  final String name;
  final String imageUrl;
  const _Category({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
}
