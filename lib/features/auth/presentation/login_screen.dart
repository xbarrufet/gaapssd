import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../chat/data/chat_repository.dart';
import '../../visits/data/visits_repository.dart';
import '../../visits/presentation/assigned_gardens_visit_status_screen.dart';
import '../../visits/presentation/client_visits_screen.dart';
import '../../visits/presentation/gardener_visits_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.visitsRepository,
    required this.chatRepository,
  });

  final VisitsRepository visitsRepository;
  final ChatRepository chatRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn({required bool asClient}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => asClient
            ? ClientVisitsScreen(repository: widget.visitsRepository)
            : GardenerVisitsListScreen(repository: widget.visitsRepository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        child: const Icon(
                          Icons.local_florist_rounded,
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
                                ),
                                const SizedBox(height: 14),
                                _LabeledField(
                                  label: 'Password',
                                  controller: _passwordController,
                                  hint: '••••••••',
                                  obscureText: true,
                                  suffix: TextButton(
                                    onPressed: () {},
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
                                      child: FilledButton.icon(
                                        onPressed: () => _signIn(asClient: true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.onPrimary,
                                          minimumSize: const Size.fromHeight(52),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        icon: const Icon(Icons.person_rounded),
                                        label: Text(
                                          'Sign In Client',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(color: AppColors.onPrimary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _signIn(asClient: false),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.secondary,
                                          foregroundColor: AppColors.onPrimary,
                                          minimumSize: const Size.fromHeight(52),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        icon: const Icon(Icons.eco_rounded),
                                        label: Text(
                                          'Sign In Gardener',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(color: AppColors.onPrimary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Selecciona el perfil per entrar al prototip',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 12,
                                      ),
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
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Spacer(),
            if (suffix != null) ...[suffix!],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surfaceHigh.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.18)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.45)),
            ),
          ),
        ),
      ],
    );
  }
}