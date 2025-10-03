import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';

// Registration state
class RegistrationState {
  final bool isLoading;
  final String? error;
  final String? phoneNumber;
  final String? email;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? address;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final int
  currentStep; // 0: personal info, 1: phone, 2: verification, 3: complete

  const RegistrationState({
    this.isLoading = false,
    this.error,
    this.phoneNumber,
    this.email,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.address,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.currentStep = 0,
  });

  RegistrationState copyWith({
    bool? isLoading,
    String? error,
    String? phoneNumber,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? address,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    int? currentStep,
  }) {
    return RegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

// Registration controller
class RegistrationController extends StateNotifier<RegistrationState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  RegistrationController(this._authRepository, this._userRepository)
    : super(const RegistrationState());

  // Step 1: Update personal information (first step)
  Future<void> updatePersonalInfoFirst({
    required String firstName,
    required String lastName,
    String? email,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if email already exists (if provided)
      if (email != null && email.isNotEmpty) {
        final emailExists = await _userRepository.isEmailExists(email);
        if (emailExists) {
          throw Exception('Email này đã được đăng ký');
        }
      }

      // Update state
      state = state.copyWith(
        isLoading: false,
        firstName: firstName,
        lastName: lastName,
        email: email,
        dateOfBirth: dateOfBirth,
        address: address,
        currentStep: 1, // Move to phone step
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Step 2: Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if phone number already exists
      final phoneExists = await _userRepository.isPhoneNumberExists(
        phoneNumber,
      );
      if (phoneExists) {
        throw Exception('Số điện thoại này đã được đăng ký');
      }

      // Send OTP
      await _authRepository.sendOTP(phoneNumber);

      state = state.copyWith(
        isLoading: false,
        phoneNumber: phoneNumber,
        currentStep: 2, // Move to verification step
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Step 3: Verify OTP and complete registration
  Future<void> verifyOTPAndCompleteRegistration(String otpCode) async {
    print('🔐 Debug: Starting OTP verification and complete registration');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Verify OTP
      print('🔍 Debug: Verifying OTP...');
      await _authRepository.verifyOTP(otpCode);
      print('✅ Debug: OTP verification successful');

      // Complete registration
      print('🔍 Debug: Completing registration...');
      await completeRegistration();
      print('✅ Debug: Registration completed successfully');
    } catch (e) {
      print('❌ Debug: Error in verifyOTPAndCompleteRegistration: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Step 4: Complete registration
  Future<void> completeRegistration() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current user
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        throw Exception('Người dùng không tồn tại');
      }

      // Create complete user profile
      final userModel = UserModel(
        uid: currentUser.uid,
        phoneNumber: state.phoneNumber!,
        email: state.email,
        displayName: '${state.firstName} ${state.lastName}',
        firstName: state.firstName,
        lastName: state.lastName,
        dateOfBirth: state.dateOfBirth,
        address: state.address,
        isEmailVerified: state.email != null ? false : true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('🔍 Debug: Created UserModel: ${userModel.toMap()}');
      print('🔍 Debug: User UID: ${currentUser.uid}');
      print('🔍 Debug: Phone number: ${state.phoneNumber}');

      // Create user profile in Firestore
      await _userRepository.createUserProfile(userModel);

      // Sign out user after successful registration
      await _authRepository.signOut();

      state = state.copyWith(isLoading: false, currentStep: 4);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Resend OTP
  Future<void> resendOTP() async {
    if (state.phoneNumber == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.resendOTP();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Reset registration
  void resetRegistration() {
    state = const RegistrationState();
  }

  // Reset state after successful registration
  void resetState() {
    state = const RegistrationState();
  }

  // Go to specific step
  void goToStep(int step) {
    state = state.copyWith(currentStep: step);
  }
}

// Providers
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final registrationControllerProvider =
    StateNotifierProvider<RegistrationController, RegistrationState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      final userRepository = ref.watch(userRepositoryProvider);
      return RegistrationController(authRepository, userRepository);
    });

// Current user profile provider
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getCurrentUserProfileStream();
});
