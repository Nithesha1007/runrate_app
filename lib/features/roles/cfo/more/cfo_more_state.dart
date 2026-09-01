import 'package:equatable/equatable.dart';

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

class CfoProfile extends Equatable {
  const CfoProfile({
    required this.name,
    required this.roleLabel,
    required this.department,
    this.avatarUrl,
  });

  final String name;
  final String roleLabel; // e.g. "CFO / Finance"
  final String department; // e.g. "Finance"
  final String? avatarUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  List<Object?> get props => [name, roleLabel, department, avatarUrl];
}

/// ---------------------------------------------------------------------
/// State
/// ---------------------------------------------------------------------

abstract class CfoMoreState extends Equatable {
  const CfoMoreState();

  @override
  List<Object?> get props => [];
}

class CfoMoreInitial extends CfoMoreState {
  const CfoMoreInitial();
}

class CfoMoreLoading extends CfoMoreState {
  const CfoMoreLoading();
}

class CfoMoreLoaded extends CfoMoreState {
  const CfoMoreLoaded({
    required this.profile,
    required this.departmentsManaged,
    required this.aiBudgetAllocation,
    required this.walletBalance,
    required this.savingsInsightsNewCount,
    required this.notificationsCount,
    required this.appVersion,
    this.isLoggingOut = false,
  });

  final CfoProfile profile;
  final int departmentsManaged;
  final String aiBudgetAllocation; // e.g. "$3.10M allocation"
  final String walletBalance; // e.g. "$14.2k available"
  final int savingsInsightsNewCount;
  final int notificationsCount;
  final String appVersion; // e.g. "v2.4.1"
  final bool isLoggingOut;

  CfoMoreLoaded copyWith({
    CfoProfile? profile,
    int? departmentsManaged,
    String? aiBudgetAllocation,
    String? walletBalance,
    int? savingsInsightsNewCount,
    int? notificationsCount,
    String? appVersion,
    bool? isLoggingOut,
  }) {
    return CfoMoreLoaded(
      profile: profile ?? this.profile,
      departmentsManaged: departmentsManaged ?? this.departmentsManaged,
      aiBudgetAllocation: aiBudgetAllocation ?? this.aiBudgetAllocation,
      walletBalance: walletBalance ?? this.walletBalance,
      savingsInsightsNewCount: savingsInsightsNewCount ?? this.savingsInsightsNewCount,
      notificationsCount: notificationsCount ?? this.notificationsCount,
      appVersion: appVersion ?? this.appVersion,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        departmentsManaged,
        aiBudgetAllocation,
        walletBalance,
        savingsInsightsNewCount,
        notificationsCount,
        appVersion,
        isLoggingOut,
      ];
}

class CfoMoreError extends CfoMoreState {
  const CfoMoreError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CfoMoreLoggedOut extends CfoMoreState {
  const CfoMoreLoggedOut();
}