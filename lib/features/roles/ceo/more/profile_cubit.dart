import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable snapshot of the signed-in user's profile. Read this anywhere
/// in the app via `context.watch<ProfileCubit>().state`.
class ProfileState extends Equatable {
  const ProfileState({
    this.name = '',
    this.role = '',
    this.organization = '',
    this.email = '',
    this.phone = '',
    this.avatarUrl,
    this.isLoaded = false,
  });

  final String name;
  final String role;
  final String organization;
  final String email;
  final String phone;
  final String? avatarUrl;

  /// True once real data has been hydrated from storage or a login
  /// response. Screens can use this to show a skeleton instead of an
  /// empty name on first frame.
  final bool isLoaded;

  String? get avatarPath => avatarUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  ProfileState copyWith({
    String? name,
    String? role,
    String? organization,
    String? email,
    String? phone,
    String? avatarUrl,
    bool clearAvatar = false,
    bool? isLoaded,
  }) {
    return ProfileState(
      name: name ?? this.name,
      role: role ?? this.role,
      organization: organization ?? this.organization,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'organization': organization,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
      };

  factory ProfileState.fromJson(Map<String, dynamic> json) => ProfileState(
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        organization: json['organization'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        isLoaded: true,
      );

  @override
  List<Object?> get props => [
        name,
        role,
        organization,
        email,
        phone,
        avatarUrl,
        isLoaded,
      ];
}

/// Holds the current user's profile and persists it locally via
/// shared_preferences, so name/role/organization survive an app restart
/// without re-fetching. Provide this once above MaterialApp (same level as
/// ThemeCubit) so every role dashboard can read from it.
///
/// Wiring:
/// 1. On app start, call `hydrate()` before first paint (e.g. in a splash
///    screen or main()) to restore whatever was saved last session.
/// 2. Right after a successful login, call `loadFromAuthResponse(json)`
///    with the raw login payload.
/// 3. Anywhere a user edits their profile (CeoProfileEditScreen), call
///    `updateProfile(...)` — this updates the in-memory state AND storage,
///    so every screen watching the cubit (hero cards, dashboard headers)
///    updates immediately.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState());

  static const _prefsKey = 'profile_data_v1';

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      emit(ProfileState.fromJson(json));
    } catch (_) {
      // Corrupt or legacy cache shape — fall back to the empty default
      // rather than crash startup.
    }
  }

  /// Call with the raw login/auth response. Adjust the key lookups below
  /// if your API uses different field names.
  Future<void> loadFromAuthResponse(Map<String, dynamic> json) async {
    final authProfile = ProfileState(
      name: (json['name'] ?? json['fullName'] ?? '') as String,
      role: (json['role'] ?? json['title'] ?? 'CEO') as String,
      organization: (json['organization'] ?? json['company'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? json['phoneNumber'] ?? '') as String,
      avatarUrl: json['avatarUrl'] as String?,
      isLoaded: true,
    );

    final next = state.isLoaded
        ? state.copyWith(
            role: authProfile.role,
            email: authProfile.email,
            isLoaded: true,
          )
        : authProfile;
    emit(next);
    await _persist(next);
  }

  /// Partial update used by CeoProfileEditScreen on save. Only the fields
  /// passed in are changed; everything else is kept as-is.
  Future<void> updateProfile({
    String? name,
    String? organization,
    String? phone,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final next = state.copyWith(
      name: name,
      organization: organization,
      phone: phone,
      avatarUrl: avatarUrl,
      clearAvatar: clearAvatar,
      isLoaded: true,
    );
    emit(next);
    await _persist(next);
  }

  Future<void> updateName(String name) => updateProfile(name: name);

  Future<void> updateAvatar(String? path) => updateProfile(
        avatarUrl: path,
        clearAvatar: path == null || path.isEmpty,
      );

  /// Call on logout so the next login starts clean.
  Future<void> clear() async {
    emit(const ProfileState());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _persist(ProfileState value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(value.toJson()));
  }
}
