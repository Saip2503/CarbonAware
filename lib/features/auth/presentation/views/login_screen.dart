import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../../../../core/constants/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]'), '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final credential = await authRepo.signInWithGoogle();
      if (credential != null && mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]'), '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Header Area
                  Semantics(
                    label: 'CarbonAware Logo',
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CarbonAware',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track, understand, and reduce your carbon footprint.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 36),

                  // Google Sign-In Button
                  Semantics(
                    label: 'Sign in with Google Button',
                    child: OutlinedButton.icon(
                      onPressed: (_isLoading || _isGoogleLoading)
                          ? null
                          : _signInWithGoogle,
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _GoogleLogo(),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or sign in with email',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  Semantics(
                    label: 'Email Input Field',
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  Semantics(
                    label: 'Password Input Field',
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  Semantics(
                    label: 'Sign In Button',
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading || _isGoogleLoading) ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Route Toggle
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Register',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the Google "G" logo using CustomPaint for accurate branding.
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint blue = Paint()..color = const Color(0xFF4285F4);
    final Paint red = Paint()..color = const Color(0xFFEA4335);
    final Paint yellow = Paint()..color = const Color(0xFFFBBC05);
    final Paint green = Paint()..color = const Color(0xFF34A853);
    final Paint white = Paint()..color = Colors.white;

    // Draw circle background
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, blue);

    // White inner area (simplified "G" with color blocks)
    final rect = Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8);

    // Red top-left quarter
    final pathRed = Path()
      ..moveTo(w / 2, h / 2)
      ..lineTo(w * 0.1, h * 0.1)
      ..arcTo(rect, -3.14, 1.57, false)
      ..close();
    canvas.drawPath(pathRed, red);

    // Yellow top-right quarter
    final pathYellow = Path()
      ..moveTo(w / 2, h / 2)
      ..lineTo(w * 0.9, h * 0.1)
      ..arcTo(rect, -1.57, 1.57, false)
      ..close();
    canvas.drawPath(pathYellow, yellow);

    // Green bottom-right quarter
    final pathGreen = Path()
      ..moveTo(w / 2, h / 2)
      ..lineTo(w * 0.9, h * 0.9)
      ..arcTo(rect, 0, 1.57, false)
      ..close();
    canvas.drawPath(pathGreen, green);

    // Blue bottom-left quarter
    final pathBlue = Path()
      ..moveTo(w / 2, h / 2)
      ..lineTo(w * 0.1, h * 0.9)
      ..arcTo(rect, 1.57, 1.57, false)
      ..close();
    canvas.drawPath(pathBlue, blue);

    // White circle in center (to simulate the G cutout)
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.28, white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
