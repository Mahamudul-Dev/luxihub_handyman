import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class UploadKycDocuments implements UseCase<void, UploadKycDocumentsParams> {
  final AuthRepository repository;
  const UploadKycDocuments(this.repository);

  @override
  Future<Either<Failure, void>> call(UploadKycDocumentsParams params) async {
    return await repository.uploadKycDocuments(
      userId: params.userId,
      documentType: params.documentType,
      frontImage: params.frontImage,
      backImage: params.backImage,
      selfieImage: params.selfieImage,
    );
  }
}

class UploadKycDocumentsParams extends Equatable {
  final String userId;
  final String documentType;
  final File frontImage;
  final File backImage;
  final File selfieImage;

  const UploadKycDocumentsParams({
    required this.userId,
    required this.documentType,
    required this.frontImage,
    required this.backImage,
    required this.selfieImage,
  });

  @override
  List<Object> get props => [userId, documentType, frontImage, backImage, selfieImage];
}
