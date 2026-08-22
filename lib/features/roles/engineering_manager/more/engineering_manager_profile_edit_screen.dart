import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/ceo/more/profile_cubit.dart';


/// Edit screen for an Engineering Manager's profile. Same visual language
/// as the CEO's profile edit screen, but the field set is EM-relevant:
/// name, team/department, email, phone.
///
/// Email is treated as read-only here since it's typically the login
/// identifier — flip [_emailEditable] if your product allows changing it.
class EngineeringManagerProfileEditScreen extends StatefulWidget {
  const EngineeringManagerProfileEditScreen({super.key});

  @override
  State<EngineeringManagerProfileEditScreen> createState() =>
      _EngineeringManagerProfileEditScreenState();
}

class _EngineeringManagerProfileEditScreenState extends State<EngineeringManagerProfileEditScreen> {
  static const bool _emailEditable = false;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _teamController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileCubit>().state;
    _nameController = TextEditingController(text: profile.name);
    _teamController = TextEditingController(text: profile.organization);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teamController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    try {
      await context.read<ProfileCubit>().updateProfile(
            name: _nameController.text.trim(),
            organization: _teamController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text('Edit Profile', style: AppTypography.h2(colors.textPrimary)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
            const  _FieldLabel('Full name'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Enter your full name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
          const    _FieldLabel('Team'),
              TextFormField(
                controller: _teamController,
                decoration: const InputDecoration(hintText: 'e.g. Platform Engineering'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Team is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
           const   _FieldLabel('Email'),
              TextFormField(
                controller: _emailController,
                enabled: _emailEditable,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'name@company.com',
                  helperText: _emailEditable ? null : 'Contact an admin to change your login email.',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _FieldLabel('Phone'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '+1 (555) 000-0000'),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: colors.primary),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
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
