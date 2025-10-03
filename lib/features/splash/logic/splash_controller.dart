import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/logic/auth_controller.dart';

// Splash controller
class SplashController extends StateNotifier<SplashState> {
  final Ref _ref;

  SplashController(this._ref) : super(const SplashState());

  Future<void> navigateToNextPage(BuildContext context) async {
    try {
      // Check if user is already authenticated
      final currentUser = _ref.read(currentUserProvider);

      if (currentUser != null) {
        // User is already authenticated, go to profile
        if (context.mounted) {
          context.go('/profile');
        }
      } else {
        // User is not authenticated, go to auth method selection
        if (context.mounted) {
          context.go('/auth-method');
        }
      }
    } catch (e) {
      // If there's an error, default to auth method selection
      if (context.mounted) {
        context.go('/auth-method');
      }
    }
  }

  // Navigate to registration
  void navigateToRegistration(BuildContext context) {
    if (context.mounted) {
      context.go('/phone-registration');
    }
  }
}

// Splash state
class SplashState {
  final bool isLoading;
  final String? error;

  const SplashState({this.isLoading = true, this.error});

  SplashState copyWith({bool? isLoading, String? error}) {
    return SplashState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}

// Provider
final splashControllerProvider =
    StateNotifierProvider<SplashController, SplashState>((ref) {
      return SplashController(ref);
    });
