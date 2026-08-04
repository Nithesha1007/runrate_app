import 'role_enum.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final RoleEnum role;
  final String orgName;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.orgName,
  });
}
