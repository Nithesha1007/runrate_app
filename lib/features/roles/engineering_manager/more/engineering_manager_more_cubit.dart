import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MoreMenuAction { reports, blogInsights, profile, preferences, security, logOut }

class MoreMenuItem {
  const MoreMenuItem({
    required this.action,
    required this.label,
    required this.icon,
    this.isDestructive = false,
  });

  final MoreMenuAction action;
  final String label;
  final IconData icon;
  final bool isDestructive;
}

class EngineeringManagerMoreData {
  const EngineeringManagerMoreData({
    required this.name,
    required this.role,
    required this.initials,
    required this.menuItems,
  });

  final String name;
  final String role;
  final String initials;
  final List<MoreMenuItem> menuItems;
}

sealed class EngineeringManagerMoreState {
  const EngineeringManagerMoreState();
}

class EngineeringManagerMoreInitial extends EngineeringManagerMoreState {
  const EngineeringManagerMoreInitial();
}

class EngineeringManagerMoreLoading extends EngineeringManagerMoreState {
  const EngineeringManagerMoreLoading();
}

class EngineeringManagerMoreLoaded extends EngineeringManagerMoreState {
  const EngineeringManagerMoreLoaded(this.data);

  final EngineeringManagerMoreData data;
}

class EngineeringManagerMoreError extends EngineeringManagerMoreState {
  const EngineeringManagerMoreError(this.message);

  final String message;
}

/// Cubit for Engineering Manager · More.
///
/// `loadProfile()` calls a mock repository method with an artificial delay
/// per spec section 12. Swap `_fetchMockProfile()` for a real repository
/// call once the API is available.
class EngineeringManagerMoreCubit extends Cubit<EngineeringManagerMoreState> {
  EngineeringManagerMoreCubit() : super(const EngineeringManagerMoreInitial());

  Future<void> loadProfile() async {
    emit(const EngineeringManagerMoreLoading());
    try {
      final data = await _fetchMockProfile();
      emit(EngineeringManagerMoreLoaded(data));
    } catch (e) {
      emit(EngineeringManagerMoreError(e.toString()));
    }
  }

  Future<EngineeringManagerMoreData> _fetchMockProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const EngineeringManagerMoreData(
      name: 'Priya Nair',
      role: 'Engineering Manager · Platform',
      initials: 'PN',
      menuItems: [
        MoreMenuItem(action: MoreMenuAction.reports, label: 'Reports', icon: Icons.bar_chart_outlined),
        MoreMenuItem(
          action: MoreMenuAction.blogInsights,
          label: 'Blog & insights',
          icon: Icons.article_outlined,
        ),
        MoreMenuItem(action: MoreMenuAction.profile, label: 'Profile', icon: Icons.person_outline),
        MoreMenuItem(
          action: MoreMenuAction.preferences,
          label: 'Preferences',
          icon: Icons.tune_outlined,
        ),
        MoreMenuItem(action: MoreMenuAction.security, label: 'Security', icon: Icons.lock_outline),
        MoreMenuItem(
          action: MoreMenuAction.logOut,
          label: 'Log out',
          icon: Icons.logout,
          isDestructive: true,
        ),
      ],
    );
  }
}