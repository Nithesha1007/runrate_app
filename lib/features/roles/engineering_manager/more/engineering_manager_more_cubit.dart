import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// All tappable destinations on the Engineering Manager · More screen.
///
/// TODO: confirm/replace with your project's real named routes when wiring
/// _handleTap in the screen file.
enum MoreMenuAction {
  editProfile,
  switchWorkspace,
  reportEngineeringSpend,
  reportAiUsage,
  reportTeamPerformance,
  notifications,
  preferences,
  changePassword,
  twoFactorAuth,
  biometricLock,
  activeSessions,
  privacySettings,
  helpCenter,
  faqs,
  contactSupport,
  reportProblem,
  sendFeedback,
  aboutRunrate,
  termsOfService,
  privacyPolicy,
  licenses,
  deleteAccount,
  logOut,
}

/// A single compact settings row: icon, title, optional subtitle/value,
/// optional "coming soon" / destructive styling.
class MoreRow {
  const MoreRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingValue,
    this.action,
    this.isDestructive = false,
    this.isComingSoon = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingValue;
  final MoreMenuAction? action;
  final bool isDestructive;

  /// Feature not yet backed by the API — row is shown but disabled/labelled
  /// "Coming soon" instead of faking behavior.
  final bool isComingSoon;
}

/// A titled group of rows (e.g. "Reports & Insights", "Security & Privacy").
class MoreSection {
  const MoreSection({required this.title, required this.rows});

  final String title;
  final List<MoreRow> rows;
}

class ProfileInfo {
  const ProfileInfo({
    required this.name,
    required this.role,
    required this.department,
    required this.company,
    required this.initials,
    this.avatarUrl,
  });

  final String name;
  final String role;
  final String department;
  final String company;
  final String initials;
  final String? avatarUrl;
}

class WorkspaceInfo {
  const WorkspaceInfo({
    required this.companyName,
    required this.departmentName,
    required this.canSwitch,
  });

  final String companyName;
  final String departmentName;

  /// Only true if the app already has multi-workspace support. Governs
  /// whether the "Switch Workspace" row is shown at all — see spec §2.
  final bool canSwitch;
}

class EngineeringManagerMoreData {
  const EngineeringManagerMoreData({
    required this.profile,
    required this.workspace,
    required this.permissions,
    required this.sections,
    required this.supportsDeleteAccount,
  });

  final ProfileInfo profile;
  final WorkspaceInfo workspace;

  /// Read-only permission list shown under Account & Access (spec §7).
  /// Role changes are intentionally not editable here.
  final List<String> permissions;

  final List<MoreSection> sections;

  /// Only show the Delete Account row if the backend actually supports it
  /// (spec §11). Defaults to false until confirmed.
  final bool supportsDeleteAccount;
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
/// `loadProfile()` currently calls a mock repository method with an
/// artificial delay. Swap `_fetchMockProfile()` for your real
/// profile/settings repository call(s) once available — ideally combining
/// a profile fetch + a settings/permissions fetch and mapping both into
/// [EngineeringManagerMoreData].
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

    const profile = ProfileInfo(
      name: 'Priya Nair',
      role: 'Engineering Manager',
      department: 'Engineering',
      company: 'Runrate',
      initials: 'PN',
    );

    // TODO: flip canSwitch to true only if multi-workspace already exists
    // in your app — do not fake this per spec §2.
    const workspace = WorkspaceInfo(
      companyName: 'Runrate Technologies',
      departmentName: 'Engineering',
      canSwitch: false,
    );

    const permissions = [
      'Team Management',
      'Engineering Approvals',
      'AI Usage',
      'Engineering Reports',
    ];

    final sections = [
      const MoreSection(
        title: 'Reports & Insights',
        rows: [
          MoreRow(
            icon: Icons.bar_chart_outlined,
            title: 'Engineering Spend',
            subtitle: 'View team AI spending',
            action: MoreMenuAction.reportEngineeringSpend,
          ),
          MoreRow(
            icon: Icons.smart_toy_outlined,
            title: 'AI Usage',
            subtitle: 'View tool usage and adoption',
            action: MoreMenuAction.reportAiUsage,
          ),
          MoreRow(
            icon: Icons.trending_up_outlined,
            title: 'Team Performance',
            subtitle: 'View engineering team trends',
            action: MoreMenuAction.reportTeamPerformance,
          ),
        ],
      ),
      const MoreSection(
        title: 'Notifications',
        rows: [
          MoreRow(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage how you receive updates',
            action: MoreMenuAction.notifications,
          ),
        ],
      ),
      const MoreSection(
        title: 'Preferences',
        rows: [
          MoreRow(
            icon: Icons.tune_outlined,
            title: 'Preferences',
            subtitle: 'Appearance, language, currency, date & time',
            action: MoreMenuAction.preferences,
          ),
        ],
      ),
      const MoreSection(
        title: 'Security & Privacy',
        rows: [
          MoreRow(
            icon: Icons.lock_outline,
            title: 'Change Password',
            action: MoreMenuAction.changePassword,
          ),
          MoreRow(
            icon: Icons.verified_user_outlined,
            title: 'Two-Factor Authentication',
            action: MoreMenuAction.twoFactorAuth,
            isComingSoon: true, // TODO: flip once backend supports 2FA
          ),
          MoreRow(
            icon: Icons.fingerprint,
            title: 'Biometric Lock',
            action: MoreMenuAction.biometricLock,
            isComingSoon: true, // TODO: flip once device-level lock exists
          ),
          MoreRow(
            icon: Icons.devices_outlined,
            title: 'Active Sessions',
            action: MoreMenuAction.activeSessions,
            isComingSoon: true, // TODO: flip once session listing exists
          ),
          MoreRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Settings',
            action: MoreMenuAction.privacySettings,
          ),
        ],
      ),
      const MoreSection(
        title: 'Help & Support',
        rows: [
          MoreRow(
            icon: Icons.help_outline,
            title: 'Help Center',
            action: MoreMenuAction.helpCenter,
          ),
          MoreRow(
            icon: Icons.quiz_outlined,
            title: 'FAQs',
            action: MoreMenuAction.faqs,
          ),
          MoreRow(
            icon: Icons.support_agent_outlined,
            title: 'Contact Support',
            action: MoreMenuAction.contactSupport,
          ),
          MoreRow(
            icon: Icons.flag_outlined,
            title: 'Report a Problem',
            action: MoreMenuAction.reportProblem,
          ),
          MoreRow(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            action: MoreMenuAction.sendFeedback,
          ),
        ],
      ),
      const MoreSection(
        title: 'About Runrate',
        rows: [
          MoreRow(
            icon: Icons.info_outline,
            title: 'About Runrate',
            action: MoreMenuAction.aboutRunrate,
          ),
          MoreRow(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            action: MoreMenuAction.termsOfService,
          ),
          MoreRow(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            action: MoreMenuAction.privacyPolicy,
          ),
          MoreRow(
            icon: Icons.badge_outlined,
            title: 'Licenses',
            action: MoreMenuAction.licenses,
          ),
        ],
      ),
    ];

    return EngineeringManagerMoreData(
      profile: profile,
      workspace: workspace,
      permissions: permissions,
      sections: sections,
      supportsDeleteAccount: false, // TODO: flip once account deletion exists
    );
  }
}