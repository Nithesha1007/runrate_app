import 'package:get_it/get_it.dart';
import '../../features/authentication/data/mock_auth_repository.dart';

final getIt = GetIt.instance;

/// Registers repositories/services. Called once from main().
void setupDependencies() {
  getIt.registerLazySingleton<MockAuthRepository>(() => MockAuthRepository());
}
