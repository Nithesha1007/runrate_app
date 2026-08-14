import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/ceo/more/profile_cubit.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import '../em_shared_widget.dart';
import 'package:runrate/shared/widgets/scale_on_tap.dart';
import 'package:runrate/shared/widgets/staggered.dart';

/// More → Profile & Account
///
/// Deeper account detail screen, separate from the hero card + "Edit
/// Profile" flow already on the More screen (untouched). Reads/writes
/// through the existing [ProfileCubit] for the fields it already owns
/// (name, team/organization, email, phone, avatar) and keeps Department
/// / Reporting Manager as local read-only/editable fields until those
/// live on the cubit — see TODOs below.
class ProfileAccountScreen extends StatefulWidget {
  const ProfileAccountScreen({super.key});

  @override
  State<ProfileAccountScreen> createState() => _ProfileAccountScreenState();
}

class _ProfileAccountScreenState extends State<ProfileAccountScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  static const _blockCount = 3;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _departmentController;
  late final TextEditingController _teamController;

  // TODO: source from ProfileCubit once reporting-manager is exposed
  // there; treated as read-only org data for now.
  String _reportingManager = 'Not assigned';

  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    WidgetsBinding.instance.addPostFrameCallback((_) => _entrance.forward());

    final profile = context.read<ProfileCubit>().state;
    _nameController = TextEditingController(text: profile.name)
      ..addListener(_markDirty);
    _phoneController = TextEditingController(text: profile.phone)
      ..addListener(_markDirty);
    _departmentController = TextEditingController(text: 'Engineering')
      ..addListener(_markDirty);
    _teamController = TextEditingController(text: profile.organization)
      ..addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final colors = AppColors.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading:
                    Icon(Icons.photo_camera_outlined, color: colors.primary),
                title: Text('Take photo',
                    style: AppTypography.bodyLarge(colors.textPrimary)),
                onTap: () => Navigator.of(sheetContext).pop('camera'),
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library_outlined, color: colors.primary),
                title: Text('Choose from gallery',
                    style: AppTypography.bodyLarge(colors.textPrimary)),
                onTap: () => Navigator.of(sheetContext).pop('gallery'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );

    if (choice == null || !mounted) return;
    final picker = ImagePicker();
    final source =
        choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    // TODO: upload `picked.path` to your media/storage endpoint and pass
    // the resulting remote URL here instead of the local file path.
    await context.read<ProfileCubit>().updateProfile(avatarUrl: picked.path);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ProfileCubit>().updateProfile(
            name: _nameController.text.trim(),
            organization: _teamController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      // TODO: persist department / reporting manager once your backend
      // supports them on this cubit or a dedicated account-details call.
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save changes. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmScreenScaffold(
      title: 'Profile & Account',
      padded: false,
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profile) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  96, // room for the sticky save bar
                ),
                children: [
                  StaggeredFade(
                    index: 0,
                    total: _blockCount,
                    controller: _entrance,
                    child: _AccountHero(
                      profile: profile,
                      department: _departmentController.text,
                      onEditAvatar: _pickAvatar,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFade(
                    index: 1,
                    total: _blockCount,
                    controller: _entrance,
                    child: _EditableFieldsCard(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      departmentController: _departmentController,
                      teamController: _teamController,
                      email: profile.email,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFade(
                    index: 2,
                    total: _blockCount,
                    controller: _entrance,
                    child:
                        _ReadOnlyOrgCard(reportingManager: _reportingManager),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _SaveBar(
                  dirty: _dirty,
                  saving: _saving,
                  onSave: _save,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({
    required this.profile,
    required this.department,
    required this.onEditAvatar,
  });

  final ProfileState profile;
  final String department;
  final VoidCallback onEditAvatar;

  ImageProvider? _avatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    final isRemote =
        avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');
    return isRemote
        ? NetworkImage(avatarUrl)
        : FileImage(File(avatarUrl)) as ImageProvider;
  }

  @override
  Widget build(BuildContext context) {
    return EmGradientHero(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: _avatarImage(profile.avatarUrl),
                child: profile.avatarUrl == null
                    ? Text(profile.initials,
                        style: AppTypography.h2(Colors.white))
                    : null,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: ScaleOnTap(
                  onTap: onEditAvatar,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? ' ' : profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2(Colors.white),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Pill(
                        label: profile.role.isEmpty
                            ? 'Engineering Manager'
                            : profile.role),
                    if (profile.organization.isNotEmpty)
                      _Pill(label: profile.organization),
                    if (department.isNotEmpty) _Pill(label: department),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTypography.caption(Colors.white)),
    );
  }
}

class _EditableFieldsCard extends StatelessWidget {
  const _EditableFieldsCard({
    required this.nameController,
    required this.phoneController,
    required this.departmentController,
    required this.teamController,
    required this.email,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController departmentController;
  final TextEditingController teamController;
  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal information',
              style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel('Full name'),
          TextFormField(controller: nameController),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel('Email'),
          TextFormField(
            initialValue: email,
            enabled: false,
            decoration: InputDecoration(
              suffixIcon: Icon(Icons.verified, size: 18, color: colors.success),
              helperText:
                  'Verified · contact an admin to change your login email',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel('Phone'),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+91 00000 00000'),
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel('Department'),
          TextFormField(controller: departmentController),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel('Engineering team'),
          TextFormField(controller: teamController),
        ],
      ),
    );
  }
}

class _ReadOnlyOrgCard extends StatelessWidget {
  const _ReadOnlyOrgCard({required this.reportingManager});
  final String reportingManager;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workspace', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyRow(
            icon: Icons.supervisor_account_outlined,
            label: 'Reporting manager',
            value: reportingManager,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReadOnlyRow(
            icon: Icons.apartment_outlined,
            label: 'Role',
            value: 'Engineering Manager',
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child:
                Text(label, style: AppTypography.body(colors.textSecondary))),
        Text(value, style: AppTypography.bodyLarge(colors.textPrimary)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: AppTypography.label(colors.textSecondary)),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar(
      {required this.dirty, required this.saving, required this.onSave});
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.primary),
          onPressed: (dirty && !saving) ? onSave : null,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ),
    );
  }
}
