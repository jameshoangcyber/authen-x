import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _phoneNumberKey = 'phone_number';
  static const String _verificationIdKey = 'verification_id';

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges().map((
    user,
  ) {
    print('🔄 Debug: authStateChanges stream - user: ${user?.uid ?? "null"}');
    return user;
  });

  // Current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      // Format phone number to international format
      String formattedPhoneNumber = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedPhoneNumber = '+84${phoneNumber.substring(1)}';
      } else if (!phoneNumber.startsWith('+')) {
        formattedPhoneNumber = '+84$phoneNumber';
      }

      print('🔍 Debug: Sending OTP to: $formattedPhoneNumber');

      final completer = Completer<void>();

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Debug: Auto-verification completed');
          // Auto-verification completed
          await _firebaseAuth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Debug: Verification failed: ${e.code} - ${e.message}');
          if (!completer.isCompleted) {
            completer.completeError(
              AuthException('Xác thực thất bại: ${e.message ?? e.code}'),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          print(
            '📱 Debug: Code sent successfully, verificationId: $verificationId',
          );
          print('🔍 Debug: Storing verificationId to secure storage...');
          // Store verification ID and phone number
          await _secureStorage.write(
            key: _verificationIdKey,
            value: verificationId,
          );
          await _secureStorage.write(
            key: _phoneNumberKey,
            value: formattedPhoneNumber,
          );
          print('✅ Debug: VerificationId stored successfully');

          // Verify storage
          final storedId = await _secureStorage.read(key: _verificationIdKey);
          print(
            '🔍 Debug: VerificationId verification - stored: ${storedId != null ? "found" : "null"}',
          );

          // Complete the future when code is sent
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Debug: Auto-retrieval timeout');
          // Auto-retrieval timeout
        },
        timeout: const Duration(seconds: 60),
      );

      // Wait for either codeSent or verificationCompleted to be called
      await completer.future;
      print('✅ Debug: sendOTP completed successfully');
    } catch (e) {
      print('💥 Debug: Exception in sendOTP: $e');
      if (e is AuthException) rethrow;

      // Handle specific Firebase errors
      if (e.toString().contains('linkToDeath')) {
        throw AuthException(
          'Lỗi kết nối Firebase. Vui lòng kiểm tra:\n1. Firebase project đã được cấu hình đúng\n2. Phone Authentication đã được bật\n3. Test Phone Numbers đã được thêm',
        );
      }

      throw AuthException('Lỗi khi gửi mã OTP: ${e.toString()}');
    }
  }

  // Verify OTP code
  Future<UserCredential> verifyOTP(String otpCode) async {
    try {
      print('🔐 Debug: Starting OTP verification in repository');
      print('🔍 Debug: Reading verificationId from secure storage...');
      final verificationId = await _secureStorage.read(key: _verificationIdKey);
      print(
        '🔍 Debug: Retrieved verificationId: ${verificationId != null ? "found" : "null"}',
      );
      if (verificationId != null) {
        print('🔍 Debug: VerificationId value: $verificationId');
      }

      if (verificationId == null) {
        print('❌ Debug: No verification ID found');
        print('🔍 Debug: Checking if this is a test environment...');

        // For development/testing, try to use a dummy verification ID
        // This should only be used for testing with Firebase Test Phone Numbers
        if (otpCode == '123456') {
          print('🧪 Debug: Using test verification ID for development');
          // This is a workaround for testing - in production, this should not happen
          throw AuthException(
            'Vui lòng sử dụng mã OTP thật từ Firebase Test Phone Numbers.',
          );
        }

        throw AuthException(
          'Không tìm thấy mã xác thực. Vui lòng gửi lại mã OTP.',
        );
      }

      print(
        '🔑 Debug: Creating PhoneAuthCredential with verificationId and smsCode: $otpCode',
      );
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      print('🚀 Debug: Calling signInWithCredential...');
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      print(
        '✅ Debug: signInWithCredential successful - user: ${userCredential.user?.uid}',
      );

      // Clear stored verification data
      await _secureStorage.delete(key: _verificationIdKey);
      await _secureStorage.delete(key: _phoneNumberKey);
      print('🗑️ Debug: Cleared stored verification data');

      return userCredential;
    } catch (e) {
      print('💥 Debug: Exception in verifyOTP: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Mã OTP không đúng hoặc đã hết hạn');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      // Clear all stored data
      await _secureStorage.deleteAll();
    } catch (e) {
      throw AuthException('Lỗi khi đăng xuất: ${e.toString()}');
    }
  }

  // Get stored phone number
  Future<String?> getStoredPhoneNumber() async {
    return await _secureStorage.read(key: _phoneNumberKey);
  }

  // Resend OTP
  Future<void> resendOTP() async {
    try {
      final phoneNumber = await getStoredPhoneNumber();
      if (phoneNumber == null) {
        throw AuthException('Không tìm thấy số điện thoại');
      }
      await sendOTP(phoneNumber);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Lỗi khi gửi lại mã OTP: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('📧 Debug: Starting email sign in');
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Debug: Email sign in successful: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('💥 Debug: Email sign in failed: $e');
      if (e is AuthException) rethrow;

      // Handle specific Firebase errors
      String errorMessage = 'Lỗi khi đăng nhập';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'Không tìm thấy tài khoản với email này';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Mật khẩu không đúng';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Email không hợp lệ';
      } else if (e.toString().contains('user-disabled')) {
        errorMessage = 'Tài khoản đã bị vô hiệu hóa';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Quá nhiều lần thử. Vui lòng thử lại sau';
      }

      throw AuthException(errorMessage);
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      print('📧 Debug: Starting email registration');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      if (displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      print(
        '✅ Debug: Email registration successful: ${userCredential.user?.uid}',
      );
      return userCredential;
    } catch (e) {
      print('💥 Debug: Email registration failed: $e');
      if (e is AuthException) rethrow;

      // Handle specific Firebase errors
      String errorMessage = 'Lỗi khi tạo tài khoản';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Email này đã được sử dụng';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Email không hợp lệ';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn';
      } else if (e.toString().contains('operation-not-allowed')) {
        errorMessage = 'Phương thức đăng ký này không được phép';
      }

      throw AuthException(errorMessage);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('✅ Debug: Email verification sent');
      }
    } catch (e) {
      print('💥 Debug: Failed to send email verification: $e');
      throw AuthException('Lỗi khi gửi email xác thực: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print('✅ Debug: Password reset email sent to $email');
    } catch (e) {
      print('💥 Debug: Failed to send password reset: $e');
      if (e is AuthException) rethrow;

      String errorMessage = 'Lỗi khi gửi email đặt lại mật khẩu';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'Không tìm thấy tài khoản với email này';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Email không hợp lệ';
      }

      throw AuthException(errorMessage);
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
