import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? dob;
  final String? contractType;
  final double? hourlyRate;
  final String? serviceArea;
  final double? serviceLat;
  final double? serviceLng;
  final int? serviceRadiusKm;
  final String? avatarPath;
  final bool isOnline;
  final bool isKycVerified;
  final List<String> skills;

  const Profile({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.dob,
    this.contractType,
    this.hourlyRate,
    this.serviceArea,
    this.serviceLat,
    this.serviceLng,
    this.serviceRadiusKm,
    this.avatarPath,
    this.isOnline = false,
    this.isKycVerified = false,
    this.skills = const [],
  });

  Profile copyWith({
    String? name,
    String? phone,
    String? email,
    String? dob,
    String? contractType,
    double? hourlyRate,
    String? serviceArea,
    double? serviceLat,
    double? serviceLng,
    int? serviceRadiusKm,
    String? avatarPath,
    bool? isOnline,
    bool? isKycVerified,
    List<String>? skills,
  }) =>
      Profile(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        dob: dob ?? this.dob,
        contractType: contractType ?? this.contractType,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        serviceArea: serviceArea ?? this.serviceArea,
        serviceLat: serviceLat ?? this.serviceLat,
        serviceLng: serviceLng ?? this.serviceLng,
        serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
        avatarPath: avatarPath ?? this.avatarPath,
        isOnline: isOnline ?? this.isOnline,
        isKycVerified: isKycVerified ?? this.isKycVerified,
        skills: skills ?? this.skills,
      );

  @override
  List<Object?> get props => [id, name, phone, email];
}
