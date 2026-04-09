import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool get _isCupertino => Theme.of(context).platform == TargetPlatform.iOS;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _loading = false;

  Future<void> _signIn({required bool asClient}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce email y contraseña')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).signInWithEmail(
            email: email,
            password: password,
          );
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth != null) {
        context.go(auth.isClient ? AppRoutes.clientVisits : AppRoutes.gardenerVisits);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = _isCupertino;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD6E5C7), Color(0xFFA9C08E), Color(0xFFF2EEDF)],
              ),
            ),
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAlD_AzKcPcQWFZezgoaHJA0smhq6FQQ73a797S1yBFQJRkmuKGp0GPtofDEjeCDdiVErkCz6WxXbK172EIomYR0nJkh4nuBbpOXVKEAN6kZZBzdTbkjL7elMeF2rbQL9tjLX4l_SDwuStZJqaGmlxvirzCWnD120bDC1uBeg-5g3bcuOYHyP0UsQr5A76zkJqHu41N9q-5NBBr27dzZJMcMDMbZms7R3Cvr6x1X7k4HpPed-UPng0sNkszQyVjDX5O-sVsNSjyZEKj',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.expand(),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface.withValues(alpha: 0.4),
                  AppColors.surface.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCupertino ? CupertinoIcons.leaf_arrow_circlepath : Icons.local_florist_rounded,
                          size: 34,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'GAPP',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'THE ORGANIC CURATOR',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              letterSpacing: 2,
                              fontSize: 10,
                            ),
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A1C1C17),
                                  blurRadius: 28,
                                  spreadRadius: -8,
                                  offset: Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LabeledField(
                                  label: 'Email Address',
                                  controller: _emailController,
                                  hint: 'curator@garden.app',
                                  keyboardType: TextInputType.emailAddress,
                                  isCupertino: isCupertino,
                                ),
                                const SizedBox(height: 14),
                                _LabeledField(
                                  label: 'Password',
                                  controller: _passwordController,
                                  hint: '••••••••',
                                  obscureText: true,
                                  isCupertino: isCupertino,
                                  suffix: isCupertino
                                      ? CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: null,
                                          child: Text(
                                            'Forgot Password?',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(color: AppColors.primary),
                                          ),
                                        )
                                      : TextButton(
                                          onPressed: null,
                                          child: Text(
                                            'Forgot Password?',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(color: AppColors.primary),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RoleSignInButton(
                                        isCupertino: isCupertino,
                                        onPressed: () => _signIn(asClient: true),
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.onPrimary,
                                        icon: isCupertino ? CupertinoIcons.person_fill : Icons.person_rounded,
                                        label: 'Sign In Client',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _RoleSignInButton(
                                        isCupertino: isCupertino,
                                        onPressed: () => _signIn(asClient: false),
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: AppColors.onPrimary,
                                        icon: isCupertino ? CupertinoIcons.leaf_arrow_circlepath : Icons.eco_rounded,
                                        label: 'Sign In Gardener',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Selecciona el perfil per entrar al prototip',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'New to GAPP? Sign up',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label, required this.controller, required this.hint,
    required this.isCupertino, this.keyboardType, this.obscureText = false, this.suffix,
  });
  final String label; final TextEditingController controller; final String hint;
  final bool isCupertino; final TextInputType? keyboardType; final bool obscureText; final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
        const Spacer(), if (suffix != null) ...[suffix!],
      ]),
      const SizedBox(height: 6),
      isCupertino
          ? CupertinoTextField(
              controller: controller, keyboardType: keyboardType, obscureText: obscureText,
              placeholder: hint, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.18)),
              ),
            )
          : TextField(
              controller: controller, keyboardType: keyboardType, obscureText: obscureText,
              decoration: InputDecoration(
                hintText: hint, filled: true, fillColor: AppColors.surfaceHigh.withValues(alpha: 0.6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.18))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.18))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.45))),
              ),
            ),
    ]);
  }
}

class _RoleSignInButton extends StatelessWidget {
  const _RoleSignInButton({
    required this.isCupertino, required this.onPressed, required this.backgroundColor,
    required this.foregroundColor, required this.icon, required this.label,
  });
  final bool isCupertino; final VoidCallback onPressed; final Color backgroundColor;
  final Color foregroundColor; final IconData icon; final String label;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(
        onPressed: onPressed, color: backgroundColor, borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: foregroundColor, size: 18), const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foregroundColor))),
        ]),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor, foregroundColor: foregroundColor,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon),
      label: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foregroundColor)),
    );
  }
}
