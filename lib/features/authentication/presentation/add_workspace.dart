import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import 'org_selection_screen.dart' show Organization;

class AddWorkspaceScreen extends StatefulWidget {
  const AddWorkspaceScreen({super.key});

  @override
  State<AddWorkspaceScreen> createState() => _AddWorkspaceScreenState();
}

class _AddWorkspaceScreenState extends State<AddWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descController = TextEditingController();

  late final AnimationController _entrance;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _nameController.addListener(_syncSlug);
  }

  void _syncSlug() {
    final slug = _nameController.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'(^-+)|(-+$)'), '');
    _slugController.text = slug;
  }

  @override
  void dispose() {
    _entrance.dispose();
    _nameController.dispose();
    _slugController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    // TODO: replace with an actual API call to create the org.
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.of(context).pop(
      Organization(
        id: 'org_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        memberLabel: '1 member',
        icon: Icons.rocket_launch_rounded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(fade);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated gradient header — uses theme colors only.
              AnimatedBuilder(
                animation: _entrance,
                builder: (context, _) {
                  return Container(
                    height: 190,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withOpacity(0.9),
                          primary.withOpacity(0.55),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: FadeTransition(
                        opacity: fade,
                        child: SlideTransition(
                          position: slide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    icon: const Icon(Icons.arrow_back,
                                        color: Colors.white),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              Text(
                                'Add Workspace',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Set up a new organization for your team',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: slide,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Organization name',
                              hintText: 'e.g. Stellar Robotics',
                              prefixIcon: const Icon(Icons.apartment_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Organization name is required'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _slugController,
                            decoration: InputDecoration(
                              labelText: 'Workspace URL',
                              prefixText: 'runrate.com/',
                              prefixIcon: const Icon(Icons.link_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Workspace URL is required'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Description (optional)',
                              alignLabelWithHint: true,
                              prefixIcon: const Icon(Icons.notes_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          PrimaryButton(
                            label: 'Create Workspace',
                            loading: _submitting,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}