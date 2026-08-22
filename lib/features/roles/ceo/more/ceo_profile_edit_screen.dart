import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:runrate/core/theme/app_colors_data.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/toast.dart';
import 'profile_cubit.dart';

/// Full profile editor reached from the More screen's profile hero card.
/// Reads/writes the shared [ProfileCubit] so every screen watching it
/// (More hero card, dashboard headers) reflects changes immediately.
class CeoProfileEditScreen extends StatefulWidget {
  const CeoProfileEditScreen({super.key});

  @override
  State<CeoProfileEditScreen> createState() => _CeoProfileEditScreenState();
}

class _CeoProfileEditScreenState extends State<CeoProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _organizationController;
  late final TextEditingController _phoneController;

  late ProfileState _initial;
  File? _pickedImage;
  bool _clearAvatar = false;
  bool _picking = false;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _initial = context.read<ProfileCubit>().state;
    _nameController = TextEditingController(text: _initial.name)
      ..addListener(_recomputeDirty);
    _organizationController =
        TextEditingController(text: _initial.organization)
          ..addListener(_recomputeDirty);
    _phoneController = TextEditingController(text: _initial.phone)
      ..addListener(_recomputeDirty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _recomputeDirty() {
    final dirty = _nameController.text.trim() != _initial.name ||
        _organizationController.text.trim() != _initial.organization ||
        _phoneController.text.trim() != _initial.phone ||
        _pickedImage != null ||
        _clearAvatar;
    if (dirty != _dirty) setState(() => _dirty = dirty);
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_dirty) return true;
    final colors = AppColors.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
            "You have unsaved edits to your profile. If you leave now, they'll be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openImageSourceSheet() async {
    final colors = AppColors.of(context);
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Text('Update profile photo',
                style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.lg),
            _SheetOption(
              icon: Icons.photo_camera_rounded,
              label: 'Take a photo',
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from gallery',
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            if (_pickedImage != null ||
                (_initial.avatarUrl != null && !_clearAvatar)) ...[
              const SizedBox(height: AppSpacing.sm),
              _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove photo',
                isDestructive: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() {
                    _pickedImage = null;
                    _clearAvatar = true;
                  });
                  _recomputeDirty();
                },
              ),
            ],
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null && mounted) {
        setState(() {
          _pickedImage = File(file.path);
          _clearAvatar = false;
        });
        _recomputeDirty();
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_dirty || _saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {

      // endpoint here first and pass the resulting URL as `avatarUrl`
      // instead of a local file path.
      await context.read<ProfileCubit>().updateProfile(
            name: _nameController.text.trim(),
            organization: _organizationController.text.trim(),
            phone: _phoneController.text.trim(),
            avatarUrl: _pickedImage?.path,
            clearAvatar: _clearAvatar && _pickedImage == null,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppToast(context, 'Profile updated');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final profile = context.watch<ProfileCubit>().state;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscardIfNeeded() && mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                      AppSpacing.md, AppSpacing.xl, AppSpacing.md),
                  child: Row(
                    children: [
                      _ScaleOnTap(
                        onTap: () async {
                          if (await _confirmDiscardIfNeeded() && mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              color: colors.textPrimary, size: 20),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Profile',
                                style: AppTypography.h2(colors.textPrimary)),
                            Text('Keep your details up to date',
                                style: AppTypography.caption(
                                    colors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0,
                        AppSpacing.xl, 140),
                    children: [
                      _Staggered(index: 0, child: _buildHero(colors, profile)),
                      const SizedBox(height: AppSpacing.xxl),
                      _Staggered(
                        index: 1,
                        child: _FieldSection(
                          title: 'Basic Info',
                          children: [
                            _ThemedField(
                              label: 'Full Name',
                              controller: _nameController,
                              hint: 'Enter your full name',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ThemedField(
                              label: 'Role / Title',
                              controller:
                                  TextEditingController(text: profile.role),
                              enabled: false,
                              suffixIcon: Icons.lock_outline_rounded,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ThemedField(
                              label: 'Organization',
                              controller: _organizationController,
                              hint: 'Company or organization name',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Organization is required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _Staggered(
                        index: 2,
                        child: _FieldSection(
                          title: 'Contact',
                          children: [
                            _ThemedField(
                              label: 'Email',
                              controller:
                                  TextEditingController(text: profile.email),
                              enabled: false,
                              suffix: _VerifiedBadge(colors: colors),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ThemedField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              hint: 'Enter your phone number',
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
            child: _ScaleOnTap(
              onTap: _dirty && !_saving ? _save : () {},
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: _dirty
                        ? [colors.primary, colors.secondary]
                        : [
                            colors.surfaceElevated,
                            colors.surfaceElevated,
                          ],
                  ),
                  border: _dirty
                      ? null
                      : Border.all(color: colors.border),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: AppTypography.body(
                          _dirty ? Colors.white : colors.textSecondary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppColorsData colors, ProfileState profile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary,
              colors.secondary,
              colors.primary.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Column(
          children: [
            _ScaleOnTap(
              onTap: _picking ? () {} : _openImageSourceSheet,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2),
                      color: Colors.white.withValues(alpha: 0.16),
                      image: _pickedImage != null
                          ? DecorationImage(
                              image: FileImage(_pickedImage!),
                              fit: BoxFit.cover,
                            )
                          : (profile.avatarUrl != null && !_clearAvatar
                              ? DecorationImage(
                                  image: NetworkImage(profile.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    alignment: Alignment.center,
                    child: _picking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : ((_pickedImage == null &&
                                (profile.avatarUrl == null || _clearAvatar))
                            ? Text(profile.initials,
                                style: AppTypography.h2(Colors.white))
                            : null),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.background,
                        border: Border.all(color: colors.primary, width: 1.6),
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 14, color: colors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Tap the avatar to change your photo',
                style: AppTypography.caption(
                    Colors.white.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.colors});
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: colors.success),
          const SizedBox(width: 4),
          Text('Verified',
              style: AppTypography.caption(colors.success)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FieldSection extends StatelessWidget {
  const _FieldSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _ThemedField extends StatelessWidget {
  const _ThemedField({
    required this.label,
    required this.controller,
    this.hint,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.suffixIcon,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.caption(colors.textSecondary)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTypography.body(
              enabled ? colors.textPrimary : colors.textSecondary),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: AppTypography.body(colors.textSecondary),
            filled: true,
            fillColor: enabled
                ? colors.surfaceElevated
                : colors.surfaceElevated.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Center(
                        widthFactor: 1, child: suffix),
                  )
                : (suffixIcon != null
                    ? Icon(suffixIcon, color: colors.textSecondary, size: 18)
                    : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.primary, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.danger, width: 1.6),
            ),
            errorStyle: AppTypography.caption(colors.danger),
          ),
        ),
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = isDestructive ? colors.danger : colors.textPrimary;
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Text(label,
                style: AppTypography.body(color)
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 60).clamp(0, 480)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _ScaleOnTap extends StatefulWidget {
  const _ScaleOnTap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}
