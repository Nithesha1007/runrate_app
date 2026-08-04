import '../../../shared/models/user_model.dart';
import '../../../shared/models/role_enum.dart';

/// Hardcoded 5-account mock auth. No real backend.
class MockAuthRepository {
  static final _accounts = <String, ({String password, UserModel user})>{
    'ceo@runrate.com': (
      password: 'password123',
      user: const UserModel(id: 'u1', name: 'Jordan Lee', email: 'ceo@runrate.com', role: RoleEnum.ceo, orgName: 'Acme Corp'),
    ),
    'cfo@runrate.com': (
      password: 'password123',
      user: const UserModel(id: 'u2', name: 'Priya Shah', email: 'cfo@runrate.com', role: RoleEnum.cfo, orgName: 'Acme Corp'),
    ),
    'manager@runrate.com': (
      password: 'password123',
      user: const UserModel(id: 'u3', name: 'Sam Rivera', email: 'manager@runrate.com', role: RoleEnum.engineeringManager, orgName: 'Acme Corp'),
    ),
    'employee@runrate.com': (
      password: 'password123',
      user: const UserModel(id: 'u4', name: 'Alex Kim', email: 'employee@runrate.com', role: RoleEnum.employee, orgName: 'Acme Corp'),
    ),
    'admin@runrate.com': (
      password: 'password123',
      user: const UserModel(id: 'u5', name: 'Morgan Diaz', email: 'admin@runrate.com', role: RoleEnum.orgAdmin, orgName: 'Acme Corp'),
    ),
  };

  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final entry = _accounts[email.trim().toLowerCase()];
    if (entry == null || entry.password != password) {
      throw Exception('Invalid email or password');
    }
    return entry.user;
  }
}
