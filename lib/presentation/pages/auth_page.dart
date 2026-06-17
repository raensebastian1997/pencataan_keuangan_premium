import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/cubit_status.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == CubitStatus.failure && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state.mode == AuthMode.checking) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isRegister = state.mode == AuthMode.register;
        final isLoading = state.status == CubitStatus.loading;

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF032A44),
                      Color(0xFF056F87),
                      Color(0xFF42A18A),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: -130,
                left: -70,
                child: _GlowCircle(size: 260, color: Color(0x33FFD166)),
              ),
              const Positioned(
                bottom: -120,
                right: -90,
                child: _GlowCircle(size: 280, color: Color(0x2275E8D8)),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.26),
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _BrandHeader(),
                                  const SizedBox(height: 22),
                                  Text(
                                    isRegister
                                        ? 'Buat Akun Pertama'
                                        : 'Masuk ke Akun',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isRegister
                                        ? ''
                                        : 'Masuk untuk melanjutkan ke dashboard keuangan Anda.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.88,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  if (isRegister) ...[
                                    TextFormField(
                                      controller: _nameController,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'Nama lengkap',
                                        icon: Icons.person,
                                      ),
                                      validator: (value) {
                                        if ((value ?? '').trim().length < 3) {
                                          return 'Nama minimal 3 karakter.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _whatsappController,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'Nomor WhatsApp',
                                        icon: Icons.phone_rounded,
                                      ),
                                      validator: (value) {
                                        final digits = (value ?? '').replaceAll(
                                          RegExp(r'[^0-9]'),
                                          '',
                                        );
                                        if (digits.length < 10) {
                                          return 'Masukkan nomor WhatsApp yang valid.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(
                                      label: 'Email',
                                      icon: Icons.alternate_email,
                                    ),
                                    validator: (value) {
                                      final email = (value ?? '').trim();
                                      if (!email.contains('@') ||
                                          !email.contains('.')) {
                                        return 'Masukkan email yang valid.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    textInputAction: TextInputAction.done,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(
                                      label: 'Kata sandi',
                                      icon: Icons.lock,
                                      suffix: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').length < 6) {
                                        return 'Kata sandi minimal 6 karakter.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        backgroundColor: const Color(
                                          0xFFF8C85E,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF2A1A00,
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () => _submit(context, state),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                              ),
                                            )
                                          : Text(
                                              isRegister
                                                  ? 'Daftar Sekarang'
                                                  : 'Login',
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (state.hasUsers || !isRegister)
                                    Center(
                                      child: TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () {
                                                if (isRegister) {
                                                  context
                                                      .read<AuthCubit>()
                                                      .openLogin();
                                                } else {
                                                  context
                                                      .read<AuthCubit>()
                                                      .openRegister();
                                                }
                                              },
                                        child: Text(
                                          isRegister
                                              ? 'Sudah punya akun? Login'
                                              : 'Belum punya akun? Register',
                                          style: const TextStyle(
                                            color: Colors.white,
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit(BuildContext context, AuthState state) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authCubit = context.read<AuthCubit>();
    if (state.mode == AuthMode.register) {
      authCubit.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        password: _passwordController.text,
      );
      return;
    }
    authCubit.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF8C85E), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF938B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF938B), width: 1.4),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8C85E), Color(0xFFFFD980)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.shield_rounded, color: Color(0xFF3B2500)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Secure Local Finance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
