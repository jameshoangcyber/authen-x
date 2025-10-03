import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/pages/splash_page.dart';
import '../features/auth/pages/auth_method_page.dart';
import '../features/auth/pages/auth_method_register_page.dart';
import '../features/auth/pages/phone_signin_page.dart';
import '../features/auth/pages/otp_verify_page.dart';
import '../features/auth/pages/phone_registration_page.dart';
import '../features/auth/pages/personal_info_page.dart';
import '../features/auth/pages/registration_verify_page.dart';
import '../features/auth/pages/email_signin_page.dart';
import '../features/auth/pages/email_registration_page.dart';
import '../features/auth/pages/profile_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      // Auth method selection
      GoRoute(
        path: '/auth-method',
        name: 'auth-method',
        builder: (context, state) => const AuthMethodPage(),
      ),
      GoRoute(
        path: '/auth-method-register',
        name: 'auth-method-register',
        builder: (context, state) => const AuthMethodRegisterPage(),
      ),
      // Phone authentication
      GoRoute(
        path: '/phone-signin',
        name: 'phone-signin',
        builder: (context, state) => const PhoneSignInPage(),
      ),
      GoRoute(
        path: '/otp-verify',
        name: 'otp-verify',
        builder: (context, state) {
          final phoneNumber = state.extra as String?;
          return OtpVerifyPage(phoneNumber: phoneNumber ?? '');
        },
      ),
      // Registration routes
      GoRoute(
        path: '/phone-registration',
        name: 'phone-registration',
        builder: (context, state) => const PhoneRegistrationPage(),
      ),
      GoRoute(
        path: '/personal-info',
        name: 'personal-info',
        builder: (context, state) => const PersonalInfoPage(),
      ),
      GoRoute(
        path: '/registration-verify',
        name: 'registration-verify',
        builder: (context, state) => const RegistrationVerifyPage(),
      ),
      // Email authentication
      GoRoute(
        path: '/email-signin',
        name: 'email-signin',
        builder: (context, state) => const EmailSignInPage(),
      ),
      GoRoute(
        path: '/email-registration',
        name: 'email-registration',
        builder: (context, state) => const EmailRegistrationPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
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
