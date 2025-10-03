import 'package:authen_x/features/auth/logic/registration_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../models/user_model.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
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

// Email Sign In State
class EmailSignInState {
  final bool isLoading;
  final String? error;
  final bool isSignedIn;
  final User? user;

  const EmailSignInState({
    this.isLoading = false,
    this.error,
    this.isSignedIn = false,
    this.user,
  });

  EmailSignInState copyWith({
    bool? isLoading,
    String? error,
    bool? isSignedIn,
    User? user,
  }) {
    return EmailSignInState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      user: user ?? this.user,
    );
  }
}

// Email Sign In Controller
class EmailSignInController extends StateNotifier<EmailSignInState> {
  final AuthRepository _authRepository;

  EmailSignInController(this._authRepository) : super(const EmailSignInState());

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await _authRepository.signInWithEmailAndPassword(
        email,
        password,
      );
      state = state.copyWith(
        isLoading: false,
        isSignedIn: true,
        user: userCredential.user,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final emailSignInControllerProvider =
    StateNotifierProvider<EmailSignInController, EmailSignInState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return EmailSignInController(authRepository);
    });

// Email Registration State
class EmailRegistrationState {
  final bool isLoading;
  final String? error;
  final bool isRegistered;
  final User? user;

  const EmailRegistrationState({
    this.isLoading = false,
    this.error,
    this.isRegistered = false,
    this.user,
  });

  EmailRegistrationState copyWith({
    bool? isLoading,
    String? error,
    bool? isRegistered,
    User? user,
  }) {
    return EmailRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRegistered: isRegistered ?? this.isRegistered,
      user: user ?? this.user,
    );
  }
}

// Email Registration Controller
class EmailRegistrationController
    extends StateNotifier<EmailRegistrationState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  EmailRegistrationController(this._authRepository, this._userRepository)
    : super(const EmailRegistrationState());

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Create user with email and password
      final userCredential = await _authRepository
          .createUserWithEmailAndPassword(
            email,
            password,
            '${firstName} ${lastName}',
          );

      // Create user profile in Firestore
      final userModel =
          UserModel.fromFirebaseUser(
            userCredential.user!.uid,
            '', // No phone number for email registration
            email: email,
            displayName: '${firstName} ${lastName}',
          ).copyWith(
            firstName: firstName,
            lastName: lastName,
            isEmailVerified: userCredential.user!.emailVerified,
          );

      await _userRepository.createUserProfile(userModel);

      // Sign out user after successful registration
      await _authRepository.signOut();

      state = state.copyWith(
        isLoading: false,
        isRegistered: true,
        user: null, // Clear user after sign out
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetState() {
    state = const EmailRegistrationState();
  }
}

final emailRegistrationControllerProvider =
    StateNotifierProvider<EmailRegistrationController, EmailRegistrationState>((
      ref,
    ) {
      final authRepository = ref.watch(authRepositoryProvider);
      final userRepository = ref.watch(userRepositoryProvider);
      return EmailRegistrationController(authRepository, userRepository);
    });
