import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../ui/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  final VoidCallback? onBack;

  const LoginScreen({super.key, required this.onLoggedIn, this.onBack});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      setState(() => _errorMessage = 'Please enter your User ID.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.login(userId);
    if (!mounted) return;

    setState(() => _isLoading = false);
    if (result.success) {
      widget.onLoggedIn();
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.loginBackground,
            fit: BoxFit.cover,
            // Bias slightly up so more of the bridge towers stay in frame.
            alignment: const Alignment(0, -0.15),
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(gradient: AppColors.softGradient),
            ),
          ),
          // Soft top scrim for brand readability only.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18),
                ],
                stops: const [0.0, 0.18, 0.72, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(
                            AppIcons.back,
                            size: 18,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppBrand.name,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppBrand.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.35,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Open middle so the bridge photo remains the focus.
                  const Spacer(flex: 6),
                  // Login card pinned near the bottom.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AppCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('User ID', style: AppTextStyles.label),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _userIdController,
                                enabled: !_isLoading,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                onSubmitted: (_) => _submit(),
                                decoration: const InputDecoration(
                                  hintText: 'Enter your User ID',
                                  prefixIcon: Icon(
                                    AppIcons.person,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              AppGradientButton(
                                label: 'Login  →',
                                loading: _isLoading,
                                onPressed: _isLoading ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
