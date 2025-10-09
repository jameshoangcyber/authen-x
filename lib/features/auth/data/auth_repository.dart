import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'user_repository.dart';
import '../models/user_model.dart';

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

  // Check if phone number is a test number
  bool _isTestPhoneNumber(String phoneNumber) {
    // Firebase Test Phone Numbers (Vietnamese numbers)
    final firebaseTestNumbers = [
      '+84987654321', // Firebase Test Number 1 (VN)
      '+84987654322', // Firebase Test Number 2 (VN)
      '+84987654323', // Firebase Test Number 3 (VN)
      '+84987654324', // Firebase Test Number 4 (VN)
      '+84987654325', // Firebase Test Number 5 (VN)
    ];

    // Check exact Firebase test numbers first
    return firebaseTestNumbers.contains(phoneNumber);
  }

  // Check if phone number is a real number (not test)
  bool _isRealPhoneNumber(String phoneNumber) {
    return !_isTestPhoneNumber(phoneNumber);
  }

  // Get Firebase Test Numbers for reference
  List<String> getFirebaseTestNumbers() {
    return [
      '+84987654321', // Firebase Test Number 1 (VN)
      '+84987654322', // Firebase Test Number 2 (VN)
      '+84987654323', // Firebase Test Number 3 (VN)
      '+84987654324', // Firebase Test Number 4 (VN)
      '+84987654325', // Firebase Test Number 5 (VN)
    ];
  }

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

      // Check if this is a Firebase Test Number or Real Number
      if (_isTestPhoneNumber(formattedPhoneNumber)) {
        print('🧪 Debug: Detected Firebase Test Number: $formattedPhoneNumber');
        print('📱 Debug: Firebase Test Numbers use OTP: 123456');
        print('⚠️ Debug: This will NOT send real SMS');
      } else if (_isRealPhoneNumber(formattedPhoneNumber)) {
        print('📱 Debug: Detected Real Phone Number: $formattedPhoneNumber');
        print('📨 Debug: This will send REAL SMS to your phone');
        print('💰 Debug: Requires Blaze plan billing account');
      }

      final completer = Completer<void>();

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Debug: Auto-verification completed');
          // For SMS OTP flow, we don't want auto-verification
          // Let the user manually enter the OTP code
          print(
            '⚠️ Debug: Auto-verification detected, but continuing with manual OTP flow',
          );
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

  // Verify OTP and sign in/register (unified)
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
        print(
          '🔍 Debug: This might be due to auto-verification or test phone number',
        );

        // Check if this is a test phone number scenario
        final storedPhoneNumber = await _secureStorage.read(
          key: _phoneNumberKey,
        );
        print('🔍 Debug: Stored phone number: $storedPhoneNumber');

        // For Firebase Test Numbers, provide specific guidance
        if (storedPhoneNumber != null &&
            _isTestPhoneNumber(storedPhoneNumber)) {
          print('🧪 Debug: Detected Firebase Test Number: $storedPhoneNumber');
          throw AuthException(
            'Firebase Test Number detected. Please use OTP: 123456 for testing.',
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

      // Auto-create user profile if it doesn't exist
      if (userCredential.user != null) {
        await _ensureUserProfileExists(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('💥 Debug: Exception in verifyOTP: $e');
      if (e is AuthException) rethrow;

      // Enhanced error handling for different scenarios
      if (e is FirebaseAuthException) {
        print(
          '🔍 Debug: FirebaseAuthException - Code: ${e.code}, Message: ${e.message}',
        );
        switch (e.code) {
          case 'invalid-verification-code':
            throw AuthException('Mã OTP không đúng. Vui lòng kiểm tra lại.');
          case 'invalid-verification-id':
            throw AuthException(
              'Mã xác thực không hợp lệ. Vui lòng gửi lại mã OTP.',
            );
          case 'session-expired':
            throw AuthException(
              'Phiên đăng nhập đã hết hạn. Vui lòng gửi lại mã OTP.',
            );
          case 'too-many-requests':
            throw AuthException('Quá nhiều lần thử. Vui lòng thử lại sau.');
          case 'user-disabled':
            throw AuthException('Tài khoản đã bị vô hiệu hóa.');
          case 'user-not-found':
            throw AuthException(
              'Không tìm thấy tài khoản với số điện thoại này.',
            );
          case 'phone-number-already-exists':
            throw AuthException(
              'Số điện thoại này đã được sử dụng. Vui lòng đăng nhập.',
            );
          default:
            throw AuthException('Lỗi xác thực: ${e.message ?? e.code}');
        }
      }

      throw AuthException('Mã OTP không đúng hoặc đã hết hạn');
    }
  }

  // Ensure user profile exists in Firestore
  Future<void> _ensureUserProfileExists(User user) async {
    try {
      print('🔍 Debug: Ensuring user profile exists for UID: ${user.uid}');

      // Import UserModel and UserRepository here to avoid circular imports
      // This is a simplified approach - in production, you might want to inject dependencies
      final userRepository = UserRepository();
      final existingProfile = await userRepository.getUserProfile(user.uid);

      if (existingProfile == null) {
        print('🔍 Debug: User profile not found, creating new one');
        final newProfile = UserModel.fromFirebaseUser(
          user.uid,
          user.phoneNumber ?? '',
          email: user.email,
          displayName: user.displayName,
        );
        await userRepository.createUserProfile(newProfile);
        print('✅ Debug: User profile created successfully');
      } else {
        print('✅ Debug: User profile already exists');
      }
    } catch (e) {
      print('⚠️ Debug: Error ensuring user profile exists: $e');
      // Don't throw error here as it's not critical for authentication
    }
  }

  // Sign in with phone number and password
  Future<UserCredential> signInWithPassword(
    String phoneNumber,
    String password,
  ) async {
    try {
      print('🔍 Debug: Signing in with phone number and password');
      print('🔍 Debug: Phone number: $phoneNumber');

      // Format phone number to international format
      String formattedPhoneNumber = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedPhoneNumber = '+84${phoneNumber.substring(1)}';
      } else if (!phoneNumber.startsWith('+')) {
        formattedPhoneNumber = '+84$phoneNumber';
      }

      // For password-based login, we need to:
      // 1. Send OTP to get verification ID
      // 2. Sign in with OTP
      // 3. Verify password by attempting to update it
      final completer = Completer<String>();

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Debug: Auto-verification completed for password login');
          // For password login, we don't want auto-verification
        },
        verificationFailed: (FirebaseAuthException e) {
          print(
            '❌ Debug: Verification failed for password login: ${e.code} - ${e.message}',
          );
          if (!completer.isCompleted) {
            completer.completeError(
              AuthException('Xác thực thất bại: ${e.message ?? e.code}'),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          print(
            '📱 Debug: Code sent for password login, verificationId: $verificationId',
          );
          // Store verification ID temporarily
          await _secureStorage.write(
            key: _verificationIdKey,
            value: verificationId,
          );
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Debug: Auto-retrieval timeout for password login');
        },
        timeout: const Duration(seconds: 60),
      );

      // Wait for verification ID
      final verificationId = await completer.future;

      // Create credential and sign in
      // Note: This is a simplified approach for development
      // In production, you might want to implement a different flow
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode:
            '123456', // This should be replaced with actual OTP verification
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Verify the password by attempting to update it
      // If the password is wrong, this will fail
      try {
        await userCredential.user?.updatePassword(password);
        print('✅ Password verification successful');
      } catch (e) {
        // If password update fails, it means the password is wrong
        await _firebaseAuth.signOut(); // Sign out the user
        throw AuthException('Mật khẩu không đúng');
      }

      print('✅ Sign in with password successful');

      // Auto-create user profile if it doesn't exist
      if (userCredential.user != null) {
        await _ensureUserProfileExists(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('❌ Error signing in with password: $e');
      if (e is AuthException) rethrow;

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw AuthException(
              'Không tìm thấy tài khoản với số điện thoại này',
            );
          case 'wrong-password':
            throw AuthException('Mật khẩu không đúng');
          case 'invalid-credential':
            throw AuthException('Thông tin đăng nhập không hợp lệ');
          case 'too-many-requests':
            throw AuthException('Quá nhiều lần thử. Vui lòng thử lại sau');
          case 'invalid-phone-number':
            throw AuthException('Số điện thoại không hợp lệ');
          case 'missing-phone-number':
            throw AuthException('Vui lòng nhập số điện thoại');
          default:
            throw AuthException('Lỗi đăng nhập: ${e.message}');
        }
      }
      throw AuthException('Lỗi đăng nhập: $e');
    }
  }

  // Alternative method: Sign in with email and password (if email is set)
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔍 Debug: Signing in with email and password');
      print('🔍 Debug: Email: $email');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Sign in with email and password successful');
      return userCredential;
    } catch (e) {
      print('❌ Error signing in with email and password: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw AuthException('Không tìm thấy tài khoản với email này');
          case 'wrong-password':
            throw AuthException('Mật khẩu không đúng');
          case 'invalid-email':
            throw AuthException('Email không hợp lệ');
          case 'user-disabled':
            throw AuthException('Tài khoản đã bị vô hiệu hóa');
          case 'too-many-requests':
            throw AuthException('Quá nhiều lần thử. Vui lòng thử lại sau');
          default:
            throw AuthException('Lỗi đăng nhập: ${e.message}');
        }
      }
      throw AuthException('Lỗi đăng nhập: $e');
    }
  }

  // Check if user has password set up
  Future<bool> hasPasswordSet(String uid) async {
    try {
      // This would typically check Firestore for the hasPassword field
      // For now, we'll return false as a placeholder
      print('🔍 Debug: Checking if user has password set for UID: $uid');
      return false; // This should be implemented with Firestore check
    } catch (e) {
      print('❌ Error checking password status: $e');
      return false;
    }
  }

  // Reset password via email
  Future<void> resetPassword(String email) async {
    try {
      print('🔍 Debug: Sending password reset email to: $email');

      await _firebaseAuth.sendPasswordResetEmail(email: email);

      print('✅ Password reset email sent successfully');
    } catch (e) {
      print('❌ Error sending password reset email: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw AuthException('Không tìm thấy tài khoản với email này');
          case 'invalid-email':
            throw AuthException('Email không hợp lệ');
          case 'too-many-requests':
            throw AuthException('Quá nhiều lần thử. Vui lòng thử lại sau');
          default:
            throw AuthException(
              'Lỗi khi gửi email đặt lại mật khẩu: ${e.message}',
            );
        }
      }
      throw AuthException('Lỗi khi gửi email đặt lại mật khẩu: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🔍 Debug: Signing out user');

      await _firebaseAuth.signOut();

      // Clear all stored data
      await _secureStorage.deleteAll();

      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      throw AuthException('Lỗi khi đăng xuất: ${e.toString()}');
    }
  }

  // Get stored phone number
  Future<String?> getStoredPhoneNumber() async {
    try {
      return await _secureStorage.read(key: _phoneNumberKey);
    } catch (e) {
      print('❌ Error getting stored phone number: $e');
      return null;
    }
  }

  // Resend OTP
  Future<void> resendOTP() async {
    try {
      print('🔍 Debug: Resending OTP');

      final phoneNumber = await getStoredPhoneNumber();
      if (phoneNumber == null) {
        throw AuthException('Không tìm thấy số điện thoại');
      }

      await sendOTP(phoneNumber);
      print('✅ OTP resent successfully');
    } catch (e) {
      print('❌ Error resending OTP: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Lỗi khi gửi lại mã OTP: ${e.toString()}');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  // Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // Get current user phone number
  String? get currentUserPhoneNumber => _firebaseAuth.currentUser?.phoneNumber;

  // Get current user email
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  // Check if current user email is verified
  bool get isCurrentUserEmailVerified =>
      _firebaseAuth.currentUser?.emailVerified ?? false;

  // Check if current user phone is verified
  bool get isCurrentUserPhoneVerified =>
      _firebaseAuth.currentUser?.phoneNumber != null;

  // Get user creation time
  DateTime? get userCreationTime =>
      _firebaseAuth.currentUser?.metadata.creationTime;

  // Get last sign in time
  DateTime? get lastSignInTime =>
      _firebaseAuth.currentUser?.metadata.lastSignInTime;

  // Refresh user token
  Future<void> refreshUserToken() async {
    try {
      print('🔍 Debug: Refreshing user token');

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('Người dùng chưa đăng nhập');
      }

      await user.getIdToken(true); // Force refresh
      print('✅ User token refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing user token: $e');
      throw AuthException('Lỗi khi làm mới token: ${e.toString()}');
    }
  }

  // Get user ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      return await user.getIdToken(forceRefresh);
    } catch (e) {
      print('❌ Error getting ID token: $e');
      return null;
    }
  }

  // Update password for current user
  Future<void> updatePassword(String newPassword) async {
    try {
      print('🔍 Debug: Updating password for current user');

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('Người dùng chưa đăng nhập');
      }

      await user.updatePassword(newPassword);
      print('✅ Password updated successfully');
    } catch (e) {
      print('❌ Error updating password: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            throw AuthException(
              'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.',
            );
          case 'requires-recent-login':
            throw AuthException('Vui lòng đăng nhập lại để cập nhật mật khẩu.');
          case 'not-allowed':
            throw AuthException('Không được phép cập nhật mật khẩu.');
          default:
            throw AuthException('Lỗi khi cập nhật mật khẩu: ${e.message}');
        }
      }
      throw AuthException('Lỗi khi cập nhật mật khẩu: $e');
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateUser(String password) async {
    try {
      print('🔍 Debug: Re-authenticating user');

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('Người dùng chưa đăng nhập');
      }

      // For phone auth users, we need to re-authenticate with phone
      if (user.phoneNumber != null) {
        // This is a simplified approach - in production you might need
        // to implement a more sophisticated re-authentication flow
        throw AuthException('Vui lòng đăng nhập lại để thực hiện thao tác này');
      }

      // For email users, re-authenticate with email and password
      if (user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      print('✅ User re-authenticated successfully');
    } catch (e) {
      print('❌ Error re-authenticating user: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw AuthException('Mật khẩu không đúng');
          case 'user-mismatch':
            throw AuthException('Thông tin xác thực không khớp');
          case 'user-not-found':
            throw AuthException('Không tìm thấy người dùng');
          case 'invalid-credential':
            throw AuthException('Thông tin xác thực không hợp lệ');
          case 'invalid-email':
            throw AuthException('Email không hợp lệ');
          case 'too-many-requests':
            throw AuthException('Quá nhiều lần thử. Vui lòng thử lại sau');
          default:
            throw AuthException('Lỗi xác thực: ${e.message}');
        }
      }
      throw AuthException('Lỗi xác thực: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      print('🔍 Debug: Deleting user account');

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('Người dùng chưa đăng nhập');
      }

      // Re-authenticate before deleting
      await reauthenticateUser(password);

      // Delete the user account
      await user.delete();

      // Clear all stored data
      await _secureStorage.deleteAll();

      print('✅ User account deleted successfully');
    } catch (e) {
      print('❌ Error deleting user account: $e');
      if (e is AuthException) rethrow;

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'requires-recent-login':
            throw AuthException('Vui lòng đăng nhập lại để xóa tài khoản');
          case 'user-not-found':
            throw AuthException('Không tìm thấy tài khoản');
          default:
            throw AuthException('Lỗi khi xóa tài khoản: ${e.message}');
        }
      }
      throw AuthException('Lỗi khi xóa tài khoản: $e');
    }
  }
}

// Custom exception class for authentication errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
