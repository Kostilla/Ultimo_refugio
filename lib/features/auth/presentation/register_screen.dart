import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    ref.read(authLoadingProvider.notifier).state = true;

    try {
      await ref.read(authRepositoryProvider).signUp(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;
      context.go('/colony-entry');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      'Únete a Último Refugio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea tu cuenta para empezar tu colonia.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Introduce un nombre de usuario';
                        }
                        if (text.length < 3) {
                          return 'Debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Introduce un email';
                        }
                        if (!text.contains('@')) {
                          return 'Introduce un email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value ?? '';
                        if (text.isEmpty) {
                          return 'Introduce una contraseña';
                        }
                        if (text.length < 6) {
                          return 'Debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !isLoading,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value ?? '';
                        if (text.isEmpty) {
                          return 'Confirma la contraseña';
                        }
                        if (text != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: Text(
                        isLoading ? 'Creando cuenta...' : 'Crear cuenta',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: isLoading ? null : () => context.go('/login'),
                      child: const Text('Ya tengo cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}