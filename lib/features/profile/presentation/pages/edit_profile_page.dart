import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:luxihub_handyman/core/config/maps_config.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/core/utils/app_date_utils.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/contract_type_selector.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_event.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  String? _selectedContractType;
  DateTime? _selectedDob;
  double _radiusKm = 5;
  List<String> _skills = [];
  List<_Category> _categories = [];
  bool _loadingCategories = true;
  late LatLng _center;
  String? _serviceAreaText;
  String? _currentPhone;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>();

    _center = LatLng(
      widget.profile.serviceLat ?? 3.1390,
      widget.profile.serviceLng ?? 101.6869,
    );
    _selectedDob = widget.profile.dob != null
        ? DateTime.tryParse(widget.profile.dob!)
        : null;
    _nameController = TextEditingController(text: widget.profile.name);
    _dobController = TextEditingController(
        text: AppDateUtils.formatDob(widget.profile.dob));
    _hourlyRateController = TextEditingController(
      text: widget.profile.hourlyRate != null
          ? widget.profile.hourlyRate!.toStringAsFixed(2)
          : '',
    );
    _selectedContractType = widget.profile.contractType;
    _radiusKm = (widget.profile.serviceRadiusKm ?? 5).toDouble().clamp(1, 50);
    _serviceAreaText = widget.profile.serviceArea;
    _currentPhone = widget.profile.phone;
    _currentEmail = widget.profile.email;
    _skills = List.from(widget.profile.skills);
    _fetchCategories();
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

  void _toggleCategory(String name) {
    setState(() {
      if (_skills.contains(name)) {
        _skills.remove(name);
      } else {
        _skills.add(name);
      }
    });
  }

  @override
  void dispose() {
    _profileBloc.close();
    _nameController.dispose();
    _dobController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
      _dobController.text =
          AppDateUtils.formatDob(AppDateUtils.toServerDate(picked));
    }
  }

  Future<String?> _reverseGeocode(LatLng latLng) async {
    try {
      final response = await Dio().get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${latLng.latitude},${latLng.longitude}',
          'key': MapsConfig.apiKey,
        },
      );
      final results = response.data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      // Prefer a short locality name (city/suburb) over the full address.
      for (final result in results) {
        final components = result['address_components'] as List?;
        if (components == null) continue;
        for (final comp in components) {
          final types = comp['types'] as List?;
          if (types != null &&
              (types.contains('locality') ||
                  types.contains('sublocality'))) {
            return comp['long_name'] as String?;
          }
        }
      }
      return results.first['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openServiceAreaSheet() async {
    final result =
        await showModalBottomSheet<({LatLng center, double radiusKm})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceAreaSheet(
        initialCenter: _center,
        initialRadius: _radiusKm,
      ),
    );
    if (result == null) return;

    setState(() {
      _center = result.center;
      _radiusKm = result.radiusKm;
    });

    final address = await _reverseGeocode(result.center);
    if (mounted && address != null) {
      setState(() => _serviceAreaText = address);
    }
  }

  Future<void> _openChangeCredentialSheet(bool isPhone) async {
    final newValue = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangeCredentialSheet(isPhone: isPhone),
    );
    if (newValue != null && mounted) {
      setState(() {
        if (isPhone) {
          _currentPhone = newValue;
        } else {
          _currentEmail = newValue;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = Profile(
      id: widget.profile.id,
      name: _nameController.text.trim(),
      phone: _currentPhone,
      email: _currentEmail,
      dob: _selectedDob != null
          ? AppDateUtils.toServerDate(_selectedDob!)
          : null,
      contractType: _selectedContractType,
      hourlyRate: _hourlyRateController.text.isEmpty
          ? null
          : double.tryParse(_hourlyRateController.text),
      serviceArea: _serviceAreaText ?? widget.profile.serviceArea,
      serviceLat: _center.latitude,
      serviceLng: _center.longitude,
      serviceRadiusKm: _radiusKm.round(),
      avatarPath: widget.profile.avatarPath,
      isOnline: widget.profile.isOnline,
      isKycVerified: widget.profile.isKycVerified,
      skills: _skills,
    );

    _profileBloc.add(ProfileUpdateRequested(updated));
  }

  String get _serviceAreaLabel {
    final radius = '${_radiusKm.toStringAsFixed(1)} km radius';
    final area = _serviceAreaText;
    return (area != null && area.isNotEmpty) ? '$area · $radius' : radius;
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
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
                            hintText: 'Select date of birth',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        _ReadOnlyInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: _currentPhone ?? '—',
                          onTap: () => _openChangeCredentialSheet(true),
                        ),
                        SizedBox(height: 12.h),
                        _ReadOnlyInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: _currentEmail ?? '—',
                          onTap: () => _openChangeCredentialSheet(false),
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
                        ContractTypeSelector(
                          selectedType: _selectedContractType,
                          onChanged: (v) =>
                              setState(() => _selectedContractType = v),
                        ),
                        SizedBox(height: 20.h),

                        _FieldLabel(label: 'Hourly Rate (RM)'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _hourlyRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: AppTextStyles.inputText,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 50.00',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                          validator: (v) {
                            if (v != null &&
                                v.isNotEmpty &&
                                double.tryParse(v) == null) {
                              return 'Enter a valid rate';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),

                        _FieldLabel(label: 'Service Area & Radius'),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: _openServiceAreaSheet,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                  Icons.location_on_outlined),
                              suffixIcon: Icon(Icons.map_outlined,
                                  size: 20.r,
                                  color: AppColors.primary),
                              filled: true,
                            ),
                            child: Text(
                              _serviceAreaLabel,
                              style: AppTextStyles.inputText,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        _FieldLabel(label: 'Area of Skills'),
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

// ── Service area bottom sheet ────────────────────────────────────────────────

class _ServiceAreaSheet extends StatefulWidget {
  const _ServiceAreaSheet({
    required this.initialCenter,
    required this.initialRadius,
  });

  final LatLng initialCenter;
  final double initialRadius;

  @override
  State<_ServiceAreaSheet> createState() => _ServiceAreaSheetState();
}

class _ServiceAreaSheetState extends State<_ServiceAreaSheet> {
  GoogleMapController? _mapController;
  late LatLng _center;
  late double _radiusKm;

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
    _radiusKm = widget.initialRadius;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop((center: _center, radiusKm: _radiusKm));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set Your Service Area',
                          style: AppTextStyles.titleLarge
                              .copyWith(fontSize: 16.sp)),
                      SizedBox(height: 2.h),
                      Text(
                        'Drag the map to position the pin, then adjust the radius.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 12.0,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  onCameraMove: (p) =>
                      setState(() => _center = p.target),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                        EagerGestureRecognizer.new),
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId('service_area'),
                      center: _center,
                      radius: _radiusKm * 1000,
                      fillColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      strokeColor: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  },
                ),

                // Fixed centre pin
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_pin,
                          color: AppColors.primary, size: 44.r),
                      SizedBox(height: 44.h),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Radius slider + confirm
          Container(
            padding: EdgeInsets.fromLTRB(
                20.w, 16.h, 20.w, bottomPadding + 16.h),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.radio_button_checked_rounded,
                        color: AppColors.primary, size: 18.r),
                    SizedBox(width: 8.w),
                    Text(
                      'Radius: ${_radiusKm.toStringAsFixed(1)} km',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.inputBorder,
                  onChanged: (v) => setState(() => _radiusKm = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 km', style: AppTextStyles.bodySmall),
                    Text('50 km', style: AppTextStyles.bodySmall),
                  ],
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _confirm,
                  child: const Text('Confirm Service Area'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

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
              title.toUpperCase(),
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

// ── Change credential (phone / email) bottom sheet ───────────────────────────

class _ChangeCredentialSheet extends StatefulWidget {
  const _ChangeCredentialSheet({required this.isPhone});
  final bool isPhone;

  @override
  State<_ChangeCredentialSheet> createState() => _ChangeCredentialSheetState();
}

class _ChangeCredentialSheetState extends State<_ChangeCredentialSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _otpController = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _errorText;
  String _submittedValue = '';

  @override
  void dispose() {
    _valueController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _label => widget.isPhone ? 'Phone Number' : 'Email Address';
  String get _hint =>
      widget.isPhone ? '+60123456789' : 'you@example.com';

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final value = _valueController.text.trim();
    try {
      if (widget.isPhone) {
        await Supabase.instance.client.auth
            .updateUser(UserAttributes(phone: value));
      } else {
        await Supabase.instance.client.auth
            .updateUser(UserAttributes(email: value));
      }
      if (mounted) {
        setState(() {
          _codeSent = true;
          _submittedValue = value;
          _loading = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorText = 'Something went wrong. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyAndUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final otp = _otpController.text.trim();
    try {
      if (widget.isPhone) {
        await Supabase.instance.client.auth.verifyOTP(
          type: OtpType.phoneChange,
          phone: _submittedValue,
          token: otp,
        );
      } else {
        await Supabase.instance.client.auth.verifyOTP(
          type: OtpType.emailChange,
          email: _submittedValue,
          token: otp,
        );
      }

      // Also update the profiles table so the cached record stays in sync.
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final field = widget.isPhone ? 'phone' : 'email';
        await Supabase.instance.client
            .from('profiles')
            .update({field: _submittedValue})
            .eq('id', uid);
      }

      if (mounted) {
        Navigator.of(context).pop(_submittedValue);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorText = 'Invalid code. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, bottomPadding + 24.h),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              Text(
                _codeSent ? 'Enter Verification Code' : 'Change $_label',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 17.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                _codeSent
                    ? 'We sent a code to $_submittedValue. Enter it below.'
                    : 'Enter your new $_label. We\'ll send a verification code.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
              ),
              SizedBox(height: 20.h),

              if (!_codeSent) ...[
                TextFormField(
                  controller: _valueController,
                  keyboardType: widget.isPhone
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  autofocus: true,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: _hint,
                    prefixIcon: Icon(widget.isPhone
                        ? Icons.phone_outlined
                        : Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '$_label is required';
                    }
                    if (widget.isPhone &&
                        !RegExp(r'^\+?\d{7,15}$').hasMatch(v.trim())) {
                      return 'Enter a valid phone number';
                    }
                    if (!widget.isPhone &&
                        !v.trim().contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
              ] else ...[
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: AppTextStyles.inputText,
                  decoration: const InputDecoration(
                    hintText: '6-digit code',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 6) {
                      return 'Enter the 6-digit verification code';
                    }
                    return null;
                  },
                ),
              ],

              if (_errorText != null) ...[
                SizedBox(height: 8.h),
                Text(
                  _errorText!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],

              SizedBox(height: 20.h),

              ElevatedButton(
                onPressed: _loading
                    ? null
                    : (_codeSent ? _verifyAndUpdate : _sendCode),
                child: _loading
                    ? SizedBox(
                        height: 20.r,
                        width: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_codeSent
                        ? 'Verify & Update'
                        : 'Send Verification Code'),
              ),

              if (_codeSent) ...[
                SizedBox(height: 12.h),
                Center(
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _codeSent = false;
                              _otpController.clear();
                              _errorText = null;
                            }),
                    child: Text(
                      'Change $_label',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String id;
  final String name;
  final String imageUrl;
  const _Category({required this.id, required this.name, required this.imageUrl});
}

class _ReadOnlyInfoRow extends StatelessWidget {
  const _ReadOnlyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canEdit = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.r,
                color: canEdit ? AppColors.primary : AppColors.textHint),
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: canEdit
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: canEdit ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              canEdit ? 'Edit' : 'Cannot edit',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10.sp,
                color: canEdit ? AppColors.primary : AppColors.textHint,
                fontWeight: canEdit ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
