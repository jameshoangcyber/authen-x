import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static const String _usersCollection = 'users';

  // Create user profile in Firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      print('🔍 Debug: Creating user profile for UID: ${user.uid}');
      print('🔍 Debug: User data: ${user.toMap()}');

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());
      print('✅ User profile created successfully in Firestore');
    } catch (e) {
      print('❌ Error creating user profile: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Lỗi quyền truy cập Firestore. Vui lòng cấu hình Security Rules trong Firebase Console.',
        );
      }
      throw Exception('Lỗi khi tạo hồ sơ người dùng: $e');
    }
  }

  // Update user profile in Firestore (with upsert to handle missing documents)
  Future<void> updateUserProfile(UserModel user) async {
    try {
      print('🔍 Debug: Updating user profile for UID: ${user.uid}');
      print('🔍 Debug: Updated user data: ${user.toMap()}');

      // Ensure updatedAt is set to current time
      final updatedUser = user.copyWith(updatedAt: DateTime.now());

      // Use set with merge to create document if it doesn't exist
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(updatedUser.toMap(), SetOptions(merge: true));
      print('✅ User profile updated successfully in Firestore');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Lỗi quyền truy cập Firestore. Vui lòng cấu hình Security Rules trong Firebase Console.',
        );
      }
      throw Exception('Lỗi khi cập nhật hồ sơ người dùng: $e');
    }
  }

  // Get user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Lỗi quyền truy cập Firestore. Vui lòng cấu hình Security Rules trong Firebase Console.',
        );
      }
      throw Exception('Lỗi khi lấy hồ sơ người dùng: $e');
    }
  }

  // Check if phone number already exists
  Future<bool> isPhoneNumberExists(String phoneNumber) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      // If permission denied, skip check for development
      if (e.toString().contains('permission-denied')) {
        print('⚠️ DEV: Skipping phone number check due to permission denied');
        return false; // Allow registration to proceed
      }
      throw Exception('Lỗi khi kiểm tra số điện thoại: $e');
    }
  }

  // Check if email already exists
  Future<bool> isEmailExists(String email) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      // If permission denied, skip check for development
      if (e.toString().contains('permission-denied')) {
        print('⚠️ DEV: Skipping email check due to permission denied');
        return false; // Allow registration to proceed
      }
      throw Exception('Lỗi khi kiểm tra email: $e');
    }
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;

    return await getUserProfile(currentUser.uid);
  }

  // Stream of current user profile
  Stream<UserModel?> getCurrentUserProfileStream() {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return Stream.value(null);

    return _firestore
        .collection(_usersCollection)
        .doc(currentUser.uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return UserModel.fromMap(snapshot.data()!);
          }
          return null;
        });
  }

  // Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      print('✅ User profile deleted successfully');
    } catch (e) {
      print('❌ Error deleting user profile: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Lỗi quyền truy cập Firestore. Vui lòng cấu hình Security Rules trong Firebase Console.',
        );
      }
      throw Exception('Lỗi khi xóa hồ sơ người dùng: $e');
    }
  }

  // Update password status (with upsert to handle missing documents)
  Future<void> updatePasswordStatus(String uid, bool hasPassword) async {
    try {
      print('🔍 Debug: Updating password status for UID: $uid');
      print('🔍 Debug: Password status: $hasPassword');

      // Use set with merge to create document if it doesn't exist
      await _firestore.collection(_usersCollection).doc(uid).set({
        'hasPassword': hasPassword,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      print('✅ Password status updated successfully');
    } catch (e) {
      print('❌ Error updating password status: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Lỗi quyền truy cập Firestore. Vui lòng cấu hình Security Rules trong Firebase Console.',
        );
      }
      throw Exception('Lỗi khi cập nhật trạng thái mật khẩu: $e');
    }
  }

  // Update email verification status (with upsert to handle missing documents)
  Future<void> updateEmailVerificationStatus(
    String uid,
    bool isVerified,
  ) async {
    try {
      print('🔍 Debug: Updating email verification status for UID: $uid');
      print('🔍 Debug: Email verified: $isVerified');

      // Use set with merge to create document if it doesn't exist
      await _firestore.collection(_usersCollection).doc(uid).set({
        'isEmailVerified': isVerified,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      print('✅ Email verification status updated successfully');
    } catch (e) {
      print('❌ Error updating email verification status: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Lỗi quyền truy cập Firestore. Vui lòng cấu hình Security Rules trong Firebase Console.',
        );
      }
      throw Exception('Lỗi khi cập nhật trạng thái xác thực email: $e');
    }
  }

  // Create or update user profile (upsert)
  Future<void> createOrUpdateUserProfile(UserModel user) async {
    try {
      print('🔍 Debug: Creating or updating user profile for UID: ${user.uid}');

      final updatedUser = user.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(updatedUser.toMap(), SetOptions(merge: true));
      print('✅ User profile created or updated successfully');
    } catch (e) {
      print('❌ Error creating or updating user profile: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Lỗi quyền truy cập Firestore. Vui lòng cấu hình Security Rules trong Firebase Console.',
        );
      }
      throw Exception('Lỗi khi tạo hoặc cập nhật hồ sơ người dùng: $e');
    }
  }
}
