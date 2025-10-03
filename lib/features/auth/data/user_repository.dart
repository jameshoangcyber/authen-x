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

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(updatedUser.toMap());
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
    } catch (e) {
      throw Exception('Lỗi khi xóa hồ sơ người dùng: $e');
    }
  }

  // Update email verification status
  Future<void> updateEmailVerificationStatus(
    String uid,
    bool isVerified,
  ) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isEmailVerified': isVerified,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái xác thực email: $e');
    }
  }
}
