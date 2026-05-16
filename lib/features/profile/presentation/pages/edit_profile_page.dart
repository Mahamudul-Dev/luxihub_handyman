import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/skill_chip_input.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_event.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});

  final Profile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final ProfileBloc _profileBloc;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _serviceRadiusController;

  String? _selectedContractType;
  List<String> _skills = [];

  static const _contractTypes = ['Full-time', 'Part-time', 'Freelance'];

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>();
    _nameController = TextEditingController(text: widget.profile.name);
    _dobController = TextEditingController(text: widget.profile.dob ?? '');
    _hourlyRateController = TextEditingController(
      text: widget.profile.hourlyRate != null
          ? widget.profile.hourlyRate!.toStringAsFixed(2)
          : '',
    );
    _serviceRadiusController = TextEditingController(
      text: widget.profile.serviceRadiusKm?.toString() ?? '',
    );
    _selectedContractType = widget.profile.contractType;
    _skills = List.from(widget.profile.skills);
  }

  @override
  void dispose() {
    _profileBloc.close();
    _nameController.dispose();
    _dobController.dispose();
    _hourlyRateController.dispose();
    _serviceRadiusController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    DateTime? initial;
    if (_dobController.text.isNotEmpty) {
      initial = DateTime.tryParse(_dobController.text);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) {
      _dobController.text = picked.toIso8601String().substring(0, 10);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = Profile(
      id: widget.profile.id,
      name: _nameController.text.trim(),
      phone: widget.profile.phone,
      email: widget.profile.email,
      dob: _dobController.text.isEmpty ? null : _dobController.text,
      contractType: _selectedContractType,
      hourlyRate: _hourlyRateController.text.isEmpty
          ? null
          : double.tryParse(_hourlyRateController.text),
      serviceArea: widget.profile.serviceArea,
      serviceLat: widget.profile.serviceLat,
      serviceLng: widget.profile.serviceLng,
      serviceRadiusKm: _serviceRadiusController.text.isEmpty
          ? null
          : int.tryParse(_serviceRadiusController.text),
      avatarPath: widget.profile.avatarPath,
      isOnline: widget.profile.isOnline,
      isKycVerified: widget.profile.isKycVerified,
      skills: _skills,
    );

    _profileBloc.add(ProfileUpdateRequested(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _profileBloc,
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            context.pop();
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.surfaceBackground,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceBackground,
            leading: const BackButton(),
            title: Text('Edit Profile', style: AppTextStyles.titleLarge),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),

                  // ── Personal information ─────────────────────────────────
                  _SectionCard(
                    title: 'Personal Information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'Full Name'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _nameController,
                          style: AppTextStyles.inputText,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                        ),
                        SizedBox(height: 20.h),

                        _FieldLabel(label: 'Date of Birth'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          onTap: _pickDob,
                          style: AppTextStyles.inputText,
                          decoration: const InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                        ),

                        SizedBox(height: 20.h),
                        _ReadOnlyInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: widget.profile.phone ?? '—',
                        ),
                        SizedBox(height: 12.h),
                        _ReadOnlyInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: widget.profile.email ?? '—',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // ── Work information ─────────────────────────────────────
                  _SectionCard(
                    title: 'Work Information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'Contract Type'),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<String>(
                          initialValue: _contractTypes.contains(_selectedContractType)
                              ? _selectedContractType
                              : null,
                          style: AppTextStyles.inputText,
                          decoration: const InputDecoration(
                            hintText: 'Select contract type',
                            prefixIcon: Icon(Icons.handshake_outlined),
                          ),
                          items: _contractTypes
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedContractType = v),
                        ),
                        SizedBox(height: 20.h),

                        _FieldLabel(label: 'Hourly Rate (RM)'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _hourlyRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: AppTextStyles.inputText,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 50.00',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                              return 'Enter a valid rate';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),

                        _FieldLabel(label: 'Service Radius (km)'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _serviceRadiusController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: AppTextStyles.inputText,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 15',
                            prefixIcon: Icon(Icons.near_me_outlined),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                              return 'Enter a valid radius';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),

                        if (widget.profile.serviceArea != null) ...[
                          _ReadOnlyInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Service Area',
                            value: widget.profile.serviceArea!,
                          ),
                          SizedBox(height: 20.h),
                        ],

                        SkillChipInput(
                          initialSkills: _skills,
                          onChanged: (updated) => _skills = List.from(updated),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // ── Save button ──────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24.w,
                      0,
                      24.w,
                      MediaQuery.of(context).padding.bottom,
                    ),
                    child: BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        final loading = state is ProfileUpdating;
                        return ElevatedButton(
                          onPressed: loading ? null : _save,
                          child: loading
                              ? SizedBox(
                                  height: 20.r,
                                  width: 20.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Changes'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Local helpers ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.bodySmall);
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  const _ReadOnlyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.r, color: AppColors.textHint),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.textHint,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            'Cannot edit',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10.sp,
              color: AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}
