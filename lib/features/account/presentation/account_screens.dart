import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/paw_widgets.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/notifications/app_notifier.dart';
import '../application/account_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool signUp = false;
  bool obscure = true;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('PawPick account')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: BrandLogo(size: 88)),
            const SizedBox(height: 20),
            Text(signUp ? 'Join the pack.' : 'Welcome back.',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
                signUp
                    ? 'Save favorites and track every order.'
                    : 'Good things are waiting for you.',
                style: const TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            if (signUp) ...[
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: PawIconButton(
                  tooltip: obscure ? 'Show password' : 'Hide password',
                  size: 44,
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PawButton(
              label: signUp ? 'Create account' : 'Sign in',
              isLoading: ref.watch(accountProvider).isLoading,
              onPressed: ref.watch(accountProvider).isLoading
                  ? null
                  : () async {
                      final error = signUp
                          ? await ref
                              .read(accountProvider.notifier)
                              .signUp(name.text, email.text, password.text)
                          : await ref
                              .read(accountProvider.notifier)
                              .signIn(email.text, password.text);
                      if (!context.mounted) return;
                      if (error != null) {
                        AppNotifier.error('Sign-in needs another try',
                            message: error);
                      } else {
                        final firstName =
                            ref.read(accountProvider).name?.split(' ').first;
                        AppNotifier.success(
                          signUp
                              ? 'Account created'
                              : 'Welcome back${firstName == null ? '' : ', $firstName'}!',
                        );
                        context.go('/home');
                      }
                    },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Divider(height: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: AppColors.muted)),
                  ),
                  Expanded(child: Divider(height: 1)),
                ],
              ),
            ),
            PawButton(
              label: ref.watch(accountProvider).isLoading
                  ? 'Connecting to Google...'
                  : 'Continue with Google',
              variant: PawButtonVariant.google,
              height: 52,
              isLoading: ref.watch(accountProvider).isLoading,
              onPressed: ref.watch(accountProvider).isLoading
                  ? null
                  : () async {
                      final error = await ref
                          .read(accountProvider.notifier)
                          .signInWithGoogle();
                      if (error != null && context.mounted) {
                        AppNotifier.error('Google sign-in needs another try',
                            message: error);
                      } else if (context.mounted) {
                        AppNotifier.success('Welcome to the pack!');
                        context.go('/home');
                      }
                    },
            ),
            const SizedBox(height: 12),
            PawButton(
              label: 'Continue as guest',
              variant: PawButtonVariant.outline,
              icon: Icons.person_outline_rounded,
              height: 52,
              onPressed: () {
                ref.read(accountProvider.notifier).continueAsGuest();
                context.go('/home');
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: PawButton(
                label: signUp
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
                labelWidget: Text(
                  signUp
                      ? 'Already have an account? Sign in'
                      : 'New here? Create an account',
                  style: const TextStyle(decoration: TextDecoration.underline),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                ),
                variant: PawButtonVariant.text,
                height: 48,
                onPressed: () => setState(() => signUp = !signUp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
