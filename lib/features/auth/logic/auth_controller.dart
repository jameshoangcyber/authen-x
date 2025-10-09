import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../models/user_model.dart';

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Current user profile provider
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  if (currentUser == null) {
    return Stream.value(null);
  }

  return userRepository.getCurrentUserProfileStream();
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      print('👤 Debug: currentUserProvider - user: ${user?.uid ?? "null"}');
      return user;
    },
    loading: () {
      print('⏳ Debug: currentUserProvider - loading');
      return null;
    },
    error: (_, __) {
      print('❌ Debug: currentUserProvider - error');
      return null;
    },
  );
});

// Phone sign-in state
class PhoneSignInState {
  final bool isLoading;
  final String? error;
  final String? phoneNumber;
  final bool otpSent;

  const PhoneSignInState({
    this.isLoading = false,
    this.error,
    this.phoneNumber,
    this.otpSent = false,
  });

  PhoneSignInState copyWith({
    bool? isLoading,
    String? error,
    String? phoneNumber,
    bool? otpSent,
  }) {
    return PhoneSignInState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpSent: otpSent ?? this.otpSent,
    );
  }
}

// Phone sign-in controller
class PhoneSignInController extends StateNotifier<PhoneSignInState> {
  final AuthRepository _authRepository;

  PhoneSignInController(this._authRepository) : super(const PhoneSignInState());

  Future<void> sendOTP(String phoneNumber) async {
    print('🚀 Debug: Starting sendOTP for: $phoneNumber');
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.sendOTP(phoneNumber);
      print('✅ Debug: OTP sent successfully, updating state...');
      state = state.copyWith(
        isLoading: false,
        phoneNumber: phoneNumber,
        otpSent: true,
      );
      print(
        '📱 Debug: State updated - otpSent: ${state.otpSent}, phoneNumber: ${state.phoneNumber}',
      );
    } catch (e) {
      print('❌ Debug: Error in sendOTP: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final phoneSignInControllerProvider =
    StateNotifierProvider<PhoneSignInController, PhoneSignInState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return PhoneSignInController(authRepository);
    });

// OTP verification state
class OtpVerificationState {
  final bool isLoading;
  final String? error;
  final bool isResending;
  final int resendCountdown;
  final String? phoneNumber;

  const OtpVerificationState({
    this.isLoading = false,
    this.error,
    this.isResending = false,
    this.resendCountdown = 0,
    this.phoneNumber,
  });

  OtpVerificationState copyWith({
    bool? isLoading,
    String? error,
    bool? isResending,
    int? resendCountdown,
    String? phoneNumber,
  }) {
    return OtpVerificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isResending: isResending ?? this.isResending,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

// OTP verification controller
class OtpVerificationController extends StateNotifier<OtpVerificationState> {
  final AuthRepository _authRepository;

  OtpVerificationController(this._authRepository)
    : super(const OtpVerificationState());

  Future<void> verifyOTP(String otpCode) async {
    print('🔐 Debug: Starting OTP verification for code: $otpCode');
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔍 Debug: Calling authRepository.verifyOTP...');
      final userCredential = await _authRepository.verifyOTP(otpCode);
      print(
        '✅ Debug: OTP verification successful, user: ${userCredential.user?.uid}',
      );
      state = state.copyWith(isLoading: false);
      print('📱 Debug: OTP verification state updated - isLoading: false');

      // The currentUserProvider will automatically update when Firebase Auth state changes
      // No need to manually trigger it here
    } catch (e) {
      print('❌ Debug: OTP verification failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resendOTP() async {
    state = state.copyWith(isResending: true, error: null);

    try {
      await _authRepository.resendOTP();
      state = state.copyWith(isResending: false, resendCountdown: 60);
      _startCountdown();
    } catch (e) {
      state = state.copyWith(isResending: false, error: e.toString());
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (state.resendCountdown > 0) {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
        _startCountdown();
      }
    });
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setPhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
  }
}

final otpVerificationControllerProvider =
    StateNotifierProvider<OtpVerificationController, OtpVerificationState>((
      ref,
    ) {
      final authRepository = ref.watch(authRepositoryProvider);
      return OtpVerificationController(authRepository);
    });

// Password sign-in state
class PasswordSignInState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const PasswordSignInState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  PasswordSignInState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return PasswordSignInState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Password sign-in controller
class PasswordSignInController extends StateNotifier<PasswordSignInState> {
  final Ref _ref;

  PasswordSignInController(this._ref) : super(const PasswordSignInState());

  Future<void> signInWithPassword(String phoneNumber, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signInWithPassword(phoneNumber, password);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
    }
  }

  void resetState() {
    state = const PasswordSignInState();
  }
}

// Password sign-in controller provider
final passwordSignInControllerProvider =
    StateNotifierProvider<PasswordSignInController, PasswordSignInState>((ref) {
      return PasswordSignInController(ref);
    });

// Sign out controller
final signOutControllerProvider = Provider<Future<void> Function()>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return () async {
    try {
      await authRepository.signOut();
    } catch (e) {
      // Handle error if needed
      rethrow;
    }
  };
});
