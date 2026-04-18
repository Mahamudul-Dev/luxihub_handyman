import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String? phone;
  final String? email;

  const AppUser({required this.id, this.phone, this.email});

  @override
  List<Object?> get props => [id, phone, email];
}
