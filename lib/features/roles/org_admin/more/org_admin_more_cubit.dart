import 'package:flutter_bloc/flutter_bloc.dart';

enum OrgAdminMoreStatus { initial, loading, loaded, error }

class AdminProfileSummary {
  const AdminProfileSummary({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;
}

class OrgAdminMoreState {
  const OrgAdminMoreState({
    this.status = OrgAdminMoreStatus.initial,
    this.profile,
    this.isLoggingOut = false,
    this.errorMessage,
  });

  final OrgAdminMoreStatus status;
  final AdminProfileSummary? profile;
  final bool isLoggingOut;
  final String? errorMessage;

  OrgAdminMoreState copyWith({
    OrgAdminMoreStatus? status,
    AdminProfileSummary? profile,
    bool? isLoggingOut,
    String? errorMessage,
  }) {
    return OrgAdminMoreState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Org Admin · More.
/// Loads the admin's profile summary from a mock repository call (Future
/// with an artificial delay, per spec section 12).
class OrgAdminMoreCubit extends Cubit<OrgAdminMoreState> {
  OrgAdminMoreCubit() : super(const OrgAdminMoreState());

  Future<void> loadProfile() async {
    emit(state.copyWith(status: OrgAdminMoreStatus.loading));
    try {
      final profile = await _fetchMockProfile();
      emit(state.copyWith(status: OrgAdminMoreStatus.loaded, profile: profile));
    } catch (e) {
      emit(state.copyWith(
        status: OrgAdminMoreStatus.error,
        errorMessage: 'Could not load profile. Pull down to try again.',
      ));
    }
  }

  Future<void> logOut() async {
    emit(state.copyWith(isLoggingOut: true));
    await Future.delayed(const Duration(milliseconds: 600));
    // TODO: clear session/auth state and navigate to the sign-in flow.
    emit(state.copyWith(isLoggingOut: false));
  }

  Future<AdminProfileSummary> _fetchMockProfile() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const AdminProfileSummary(
      name: 'Rhea Agarwal',
      email: 'rhea@bizbharat.in',
      role: 'Org Admin',
    );
  }
}