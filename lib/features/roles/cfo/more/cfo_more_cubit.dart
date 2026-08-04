import 'package:flutter_bloc/flutter_bloc.dart';

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

class CfoProfile {
  const CfoProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
  });

  final String name;
  final String email;
  final String role;
  final String initials;
}

/// ---------------------------------------------------------------------
/// State
/// ---------------------------------------------------------------------

abstract class CfoMoreState {
  const CfoMoreState();
}

class CfoMoreInitial extends CfoMoreState {
  const CfoMoreInitial();
}

class CfoMoreLoading extends CfoMoreState {
  const CfoMoreLoading();
}

class CfoMoreLoaded extends CfoMoreState {
  const CfoMoreLoaded(this.profile, {this.isLoggingOut = false});

  final CfoProfile profile;
  final bool isLoggingOut;

  CfoMoreLoaded copyWith({CfoProfile? profile, bool? isLoggingOut}) {
    return CfoMoreLoaded(
      profile ?? this.profile,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }
}

class CfoMoreError extends CfoMoreState {
  const CfoMoreError(this.message);

  final String message;
}

class CfoMoreLoggedOut extends CfoMoreState {
  const CfoMoreLoggedOut();
}

/// ---------------------------------------------------------------------
/// Cubit
/// ---------------------------------------------------------------------

class CfoMoreCubit extends Cubit<CfoMoreState> {
  CfoMoreCubit() : super(const CfoMoreInitial()) {
    load();
  }

  Future<void> load() async {
    emit(const CfoMoreLoading());
    try {
      final profile = await _fetchProfile();
      emit(CfoMoreLoaded(profile));
    } catch (_) {
      emit(const CfoMoreError('Could not load your profile. Pull down to retry.'));
    }
  }

  Future<void> logOut() async {
    final current = state;
    if (current is! CfoMoreLoaded) return;

    emit(current.copyWith(isLoggingOut: true));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      emit(const CfoMoreLoggedOut());
    } catch (_) {
      emit(current.copyWith(isLoggingOut: false));
    }
  }

  /// Mock repository call. Replace with a real API/repository call —
  /// keep the artificial delay pattern for now per spec section 12.
  Future<CfoProfile> _fetchProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return const CfoProfile(
      name: 'Rahul Khanna',
      email: 'rahul.khanna@company.com',
      role: 'Chief Financial Officer',
      initials: 'RK',
    );
  }
}