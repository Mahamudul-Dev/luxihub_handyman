import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/document_upload_card.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

class RegistrationKycUploadPage extends StatefulWidget {
  const RegistrationKycUploadPage({super.key});

  @override
  State<RegistrationKycUploadPage> createState() =>
      _RegistrationKycUploadPageState();
}

class _RegistrationKycUploadPageState
    extends State<RegistrationKycUploadPage> {
  final ImagePicker _picker = ImagePicker();
  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _userId = state.user.id;
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        if (type == 'front') {
          _frontImage = File(image.path);
        } else if (type == 'back') {
          _backImage = File(image.path);
        } else if (type == 'selfie') {
          _selfieImage = File(image.path);
        }
      });
    }
  }

  void _onContinue() {
    if (_userId == null) {
      final state = context.read<AuthBloc>().state;
      if (state is AuthAuthenticated) {
        _userId = state.user.id;
      }
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session not found. Please log in again.')),
      );
      return;
    }

    context.read<AuthBloc>().add(AuthKycUploadRequested(
          userId: _userId!,
          documentType: 'National ID', // Default, can be dynamic
          frontImage: _frontImage!,
          backImage: _backImage!,
          selfieImage: _selfieImage!,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthKycUploaded) {
          context.push(AppRoutes.registrationTerms.path);
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(leading: const BackButton()),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RegistrationStepIndicator(currentStep: 7, totalSteps: 8),
                  SizedBox(height: 32.h),

                  // ── Heading ───────────────────────────────────────────────────
                  Text('Upload Documents', style: AppTextStyles.headlineMedium),
                  SizedBox(height: 6.h),
                  Text(
                    'Please upload clear photos of your document on both sides.',
                    style: AppTextStyles.bodyMedium,
                  ),

                  SizedBox(height: 32.h),

                  // ── Upload cards ──────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      children: [
                        DocumentUploadCard(
                          label: 'Front Side',
                          icon: Icons.credit_card_outlined,
                          isUploaded: _frontImage != null,
                          onTap: () => _pickImage('front'),
                        ),
                        SizedBox(height: 16.h),
                        DocumentUploadCard(
                          label: 'Back Side',
                          icon: Icons.credit_card_outlined,
                          isUploaded: _backImage != null,
                          onTap: () => _pickImage('back'),
                        ),
                        SizedBox(height: 16.h),
                        DocumentUploadCard(
                          label: 'Selfie with Document',
                          icon: Icons.face_outlined,
                          isUploaded: _selfieImage != null,
                          onTap: () => _pickImage('selfie'),
                        ),
                      ],
                    ),
                  ),

                  // ── Continue button ───────────────────────────────────────────
                  ElevatedButton(
                    onPressed: (isLoading ||
                            _frontImage == null ||
                            _backImage == null ||
                            _selfieImage == null)
                        ? null
                        : _onContinue,
                    child: isLoading
                        ? SizedBox(
                            height: 20.r,
                            width: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
    );
  }
}
