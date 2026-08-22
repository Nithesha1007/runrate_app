import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../roles/ceo/more/profile_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _googleLoading = false;
  bool _ssoLoading = false;

  late final AnimationController _entrance;
  late final AnimationController _bgController;

  // Staggered animations for each block on the form.
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _socialFade;
  late final Animation<Offset> _socialSlide;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    Animation<double> stagger(double start, double end) => CurvedAnimation(
          parent: _entrance,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

    _logoFade = stagger(0.0, 0.45);
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(_logoFade);

    _formFade = stagger(0.15, 0.65);
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(_formFade);

    _buttonFade = stagger(0.35, 0.8);
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(_buttonFade);

    _socialFade = stagger(0.5, 1.0);
    _socialSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(_socialFade);

    _entrance.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entrance.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
   
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _googleLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-in is not configured yet.')),
    );
  }

  Future<void> _handleSsoSignIn() async {
    setState(() => _ssoLoading = true);
   
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _ssoLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SSO sign-in is not configured yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ---- Animated futuristic gradient backdrop ----
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                final t = _bgController.value;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + t * 0.4, -1),
                      end: Alignment(1, 1 - t * 0.4),
                      colors: [
                        theme.colorScheme.surface,
                        primary.withValues(alpha: 0.06 + 0.05 * t),
                        theme.colorScheme.surface,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Soft floating glow blobs for depth.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                final t = _bgController.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -80 + 30 * t,
                      right: -60 - 20 * t,
                      child: _glowBlob(
                          size.width * 0.6, primary.withValues(alpha: 0.18)),
                    ),
                    Positioned(
                      bottom: -100 - 30 * t,
                      left: -80 + 20 * t,
                      child: _glowBlob(
                        size.width * 0.55,
                        theme.colorScheme.tertiary.withValues(alpha: 0.14),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ---- Foreground content ----
          SafeArea(
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  context.read<ProfileCubit>().loadFromAuthResponse({
                    'name': state.user.name,
                    'email': state.user.email,
                    'role': state.user.role.name,
                    'organization': state.user.orgName,
                  });
                  Navigator.of(context)
                      .pushReplacementNamed(RouteNames.orgSelection);
                }
              },
              builder: (context, state) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),

                        FadeTransition(
                          opacity: _logoFade,
                          child: SlideTransition(
                            position: _logoSlide,
                            child: Column(
                              children: [
                                _PulsingLogo(color: primary),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  AppStrings.appName,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.displayLarge,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Log in to continue',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxxl),

                        // ---- Glass card with form fields ----
                        FadeTransition(
                          opacity: _formFade,
                          child: SlideTransition(
                            position: _formSlide,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.08),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _emailController,
                                        validator: Validators.email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autocorrect: false,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          hintText: 'ceo@runrate.com',
                                          prefixIcon:
                                              const Icon(Icons.mail_outline),
                                          filled: true,
                                          fillColor: theme.colorScheme.surface
                                              .withValues(alpha: 0.6),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      TextFormField(
                                        controller: _passwordController,
                                        validator: Validators.password,
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          hintText: 'password123',
                                          prefixIcon:
                                              const Icon(Icons.lock_outline),
                                          filled: true,
                                          fillColor: theme.colorScheme.surface
                                              .withValues(alpha: 0.6),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                            ),
                                            tooltip: _obscurePassword
                                                ? 'Show password'
                                                : 'Hide password',
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      if (state is AuthError) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            state.message,
                                            style: TextStyle(
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        FadeTransition(
                          opacity: _buttonFade,
                          child: SlideTransition(
                            position: _buttonSlide,
                            child: PrimaryButton(
                              label: 'Log In',
                              loading: state is AuthLoading,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().login(
                                        _emailController.text,
                                        _passwordController.text,
                                      );
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        FadeTransition(
                          opacity: _socialFade,
                          child: SlideTransition(
                            position: _socialSlide,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        'or continue with',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Google — brand-colored "G", white pill.
                                _SocialButton(
                                  label: 'Continue with Google',
                                  loading: _googleLoading,
                                  onPressed: _handleGoogleSignIn,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  borderColor: theme.colorScheme.outline
                                      .withValues(alpha: 0.3),
                                  icon: const _GoogleG(),
                                ),
                                const SizedBox(height: AppSpacing.sm),

                                // SSO — solid brand-tinted button (uses theme primary).
                                _SocialButton(
                                  label: 'Continue with SSO',
                                  loading: _ssoLoading,
                                  onPressed: _handleSsoSignIn,
                                  backgroundColor: primary.withValues(alpha: 0.12),
                                  foregroundColor: primary,
                                  borderColor: primary.withValues(alpha: 0.35),
                                  icon: Icon(Icons.badge_outlined,
                                      color: primary, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),
                        FadeTransition(
                          opacity: _socialFade,
                          child: Text(
                            'Demo accounts: ceo@ · cfo@ · manager@ · employee@ · admin@runrate.com / password123',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// A subtly breathing app logo/mark to give the header some life.
class _PulsingLogo extends StatefulWidget {
  final Color color;
  const _PulsingLogo({required this.color});

  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: 0.35 + 0.15 * t),
                widget.color.withValues(alpha: 0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.25 + 0.15 * t),
                blurRadius: 20 + 10 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: Icon(Icons.bolt_rounded, color: widget.color, size: 34),
        );
      },
    );
  }
}

/// Google's multi-color "G" mark drawn from simple colored arcs
/// (no external asset/package required).
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const strokeWidth = 4.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Four arcs approximating the Google "G" quadrants.
    paint.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(rect, -0.35, 1.6, false, paint);
    paint.color = const Color(0xFF34A853); // green
    canvas.drawArc(rect, 1.25, 1.15, false, paint);
    paint.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(rect, 2.4, 0.9, false, paint);
    paint.color = const Color(0xFFEA4335); // red
    canvas.drawArc(rect, 3.3, 1.55, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Reusable social sign-in button with its own color identity + loading state.
class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool loading;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
