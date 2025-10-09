import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/pages/splash_page.dart';
import '../features/auth/pages/auth_method_page.dart';
import '../features/auth/pages/phone_signin_page.dart';
import '../features/auth/pages/otp_verify_page.dart';
import '../features/auth/pages/profile_page.dart';
import '../features/auth/pages/password_setup_page.dart';
import '../features/auth/pages/password_signin_page.dart';
import '../features/auth/pages/change_password_page.dart';
import '../features/auth/pages/edit_profile_page.dart';
import '../features/auth/models/user_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      // Welcome page
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      // Phone authentication (unified login/register)
      GoRoute(
        path: '/phone-signin',
        name: 'phone-signin',
        builder: (context, state) => const PhoneSignInPage(),
      ),
      // Password sign-in
      GoRoute(
        path: '/password-signin',
        name: 'password-signin',
        builder: (context, state) => const PasswordSignInPage(),
      ),
      GoRoute(
        path: '/otp-verify',
        name: 'otp-verify',
        builder: (context, state) {
          final phoneNumber = state.extra as String?;
          return OtpVerifyPage(phoneNumber: phoneNumber ?? '');
        },
      ),
      // Password setup page
      GoRoute(
        path: '/password-setup',
        name: 'password-setup',
        builder: (context, state) => const PasswordSetupPage(),
      ),
      // Change password page
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) {
          final profile = state.extra as UserModel?;
          return EditProfilePage(currentProfile: profile);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Trang không tồn tại',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Đường dẫn: ${state.uri}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
  );
});
