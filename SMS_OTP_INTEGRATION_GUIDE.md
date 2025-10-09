# Hướng dẫn tích hợp SMS OTP API vào đăng ký tài khoản

## Tổng quan

Tài liệu này hướng dẫn chi tiết cách tích hợp SMS OTP API vào quy trình đăng ký tài khoản trong ứng dụng Flutter Android sử dụng Firebase Authentication.

## Mục lục

1. [Giới thiệu SMS OTP](#giới-thiệu-sms-otp)
2. [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
3. [Cấu hình Firebase](#cấu-hình-firebase)
4. [Cài đặt dependencies](#cài-đặt-dependencies)
5. [Cấu hình Android](#cấu-hình-android)
6. [Implement SMS OTP Service](#implement-sms-otp-service)
7. [Tạo UI Components](#tạo-ui-components)
8. [Xử lý State Management](#xử-lý-state-management)
9. [Testing và Debugging](#testing-và-debugging)
10. [Troubleshooting](#troubleshooting)

## Giới thiệu SMS OTP

### SMS OTP là gì?

SMS OTP (One-Time Password) là một phương thức xác thực hai yếu tố sử dụng tin nhắn SMS để gửi mã xác thực một lần đến số điện thoại của người dùng.

### Lợi ích của SMS OTP

- Bảo mật cao: Mã OTP chỉ có hiệu lực trong thời gian ngắn
- Dễ sử dụng: Người dùng không cần cài đặt thêm ứng dụng
- Phổ biến: Hầu hết người dùng đều có điện thoại
- Tin cậy: SMS là phương thức liên lạc đáng tin cậy

### Các thành phần chính

1. **SMS Gateway**: Dịch vụ gửi tin nhắn SMS
2. **OTP Generator**: Tạo mã OTP ngẫu nhiên
3. **OTP Validator**: Xác thực mã OTP
4. **SMS Receiver**: Nhận và xử lý tin nhắn SMS
5. **Auto-fill**: Tự động điền mã OTP

## Kiến trúc hệ thống

### Sơ đồ tổng quan

```
[User] → [Mobile App] → [Firebase Auth] → [SMS Gateway] → [User's Phone]
   ↑                                                           ↓
   └── [SMS Auto-fill] ← [SMS Receiver] ← [SMS Message] ←─────┘
```

### Luồng xử lý

1. **User nhập số điện thoại**
2. **App gửi request đến Firebase Auth**
3. **Firebase gửi OTP qua SMS Gateway**
4. **User nhận tin nhắn SMS**
5. **SMS Receiver tự động điền mã OTP**
6. **User xác nhận mã OTP**
7. **App xác thực với Firebase**
8. **Hoàn tất đăng ký**

## Cấu hình Firebase

### Bước 1: Tạo Firebase Project

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Nhập tên project: "AuthenX"
4. Chọn "Enable Google Analytics" (tùy chọn)
5. Click "Create project"

### Bước 2: Thêm Android App

1. Trong Firebase Console, click "Add app" → Android
2. Nhập package name: `com.example.authen_x`
3. Tải file `google-services.json`
4. Đặt file vào thư mục `android/app/`

### Bước 3: Bật Phone Authentication

1. Vào "Authentication" → "Sign-in method"
2. Bật "Phone" provider
3. Cấu hình Test Phone Numbers:
   - Phone number: `+84901234567`
   - Verification code: `123456`
   - Phone number: `+84987654321`
   - Verification code: `654321`

### Bước 4: Cấu hình Firestore

1. Vào "Firestore Database"
2. Click "Create database"
3. Chọn "Start in test mode"
4. Chọn location gần nhất
5. Cấu hình Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Cài đặt dependencies

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.3
  
  # SMS và Security
  sms_autofill: ^2.3.0
  flutter_secure_storage: ^9.2.2
  permission_handler: ^11.3.1
  
  # State Management
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  
  # UI
  intl: ^0.19.0
  google_fonts: ^6.2.1
```

### Cài đặt dependencies

```bash
flutter pub get
```

## Cấu hình Android

### AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Internet permission for Firebase -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- SMS permissions for OTP autofill -->
    <uses-permission android:name="android.permission.RECEIVE_SMS" />
    <uses-permission android:name="android.permission.READ_SMS" />
    <uses-permission android:name="android.permission.READ_PHONE_STATE" />
    
    <!-- Notification permission for Android 13+ -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <application
        android:label="authen_x"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- SMS Receiver for OTP autofill -->
        <receiver
            android:name="com.jaumard.smsautofill.SmsReceiver"
            android:exported="true">
            <intent-filter android:priority="1000">
                <action android:name="android.provider.Telephony.SMS_RECEIVED" />
            </intent-filter>
        </receiver>
        
        <!-- Main Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### build.gradle.kts

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.authen_x"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.authen_x"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("com.google.gms:google-services:4.4.2")
}
```

## Implement SMS OTP Service

### 1. SMS Permission Helper

```dart
// lib/common/utils/sms_permission_helper.dart
class SmsPermissionHelper {
  /// Request SMS permissions for OTP autofill
  static Future<bool> requestSmsPermissions() async {
    try {
      if (await Permission.sms.isGranted) {
        return true;
      }
      final status = await Permission.sms.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting SMS permission: $e');
      return false;
    }
  }

  /// Check if SMS permissions are granted
  static Future<bool> hasSmsPermissions() async {
    try {
      return await Permission.sms.isGranted;
    } catch (e) {
      print('Error checking SMS permission: $e');
      return false;
    }
  }

  /// Open app settings if permission is denied
  static Future<void> openAppSettings() async {
    try {
      await Permission.openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}
```

### 2. Auth Repository

```dart
// lib/features/auth/data/auth_repository.dart
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FlutterSecureStorage _secureStorage;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FlutterSecureStorage secureStorage,
  }) : _firebaseAuth = firebaseAuth,
       _secureStorage = secureStorage;

  /// Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Auto verification completed');
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) async {
          print('Code sent to $phoneNumber');
          await _secureStorage.write(
            key: 'verification_id',
            value: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Error sending OTP: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify OTP code
  Future<User?> verifyOTP(String otpCode) async {
    try {
      final verificationId = await _secureStorage.read(key: 'verification_id');
      if (verificationId == null) {
        throw Exception('No verification ID found');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error verifying OTP: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _secureStorage.deleteAll();
  }
}
```

### 3. User Repository

```dart
// lib/features/auth/data/user_repository.dart
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  /// Create user profile in Firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      print('Error creating user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }
}
```

## Tạo UI Components

### 1. Phone Input Form

```dart
// lib/features/auth/widgets/phone_input_form.dart
class PhoneInputForm extends ConsumerStatefulWidget {
  const PhoneInputForm({super.key});

  @override
  ConsumerState<PhoneInputForm> createState() => _PhoneInputFormState();
}

class _PhoneInputFormState extends ConsumerState<PhoneInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _requestSmsPermission() async {
    try {
      final hasPermission = await SmsPermissionHelper.hasSmsPermissions();
      if (!hasPermission) {
        final granted = await SmsPermissionHelper.requestSmsPermissions();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cần quyền đọc SMS để tự động điền mã OTP'),
                action: SnackBarAction(
                  label: 'Cài đặt',
                  onPressed: () => SmsPermissionHelper.openAppSettings(),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error requesting SMS permission: $e');
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = _phoneController.text.trim();
      ref.read(authControllerProvider.notifier).sendOTP(phoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _phoneController,
            focusNode: _focusNode,
            label: 'Số điện thoại',
            hint: 'Nhập số điện thoại của bạn',
            keyboardType: TextInputType.phone,
            validator: Validators.phoneNumber,
            enabled: !authState.isLoading,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Gửi mã OTP',
            onPressed: authState.isLoading ? null : _submitForm,
            isLoading: authState.isLoading,
          ),
        ],
      ),
    );
  }
}
```

### 2. OTP Input Form

```dart
// lib/features/auth/widgets/otp_input_form.dart
class OtpInputForm extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpInputForm({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpInputForm> createState() => _OtpInputFormState();
}

class _OtpInputFormState extends ConsumerState<OtpInputForm> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
    _listenForSmsCode();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _requestSmsPermission() async {
    try {
      final hasPermission = await SmsPermissionHelper.hasSmsPermissions();
      if (!hasPermission) {
        final granted = await SmsPermissionHelper.requestSmsPermissions();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cần quyền đọc SMS để tự động điền mã OTP'),
                action: SnackBarAction(
                  label: 'Cài đặt',
                  onPressed: () => SmsPermissionHelper.openAppSettings(),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error requesting SMS permission: $e');
    }
  }

  void _listenForSmsCode() {
    try {
      SmsAutoFill().listenForCode;
    } catch (e) {
      print('SMS autofill not available: $e');
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final otpCode = _otpController.text.trim();
      ref.read(authControllerProvider.notifier).verifyOTP(otpCode);
    }
  }

  void _resendOTP() {
    ref.read(authControllerProvider.notifier).sendOTP(widget.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            'Nhập mã 6 chữ số đã được gửi đến',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.phoneNumber,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _otpController,
            focusNode: _focusNode,
            label: 'Mã OTP',
            hint: 'Nhập mã 6 chữ số',
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: Validators.otp,
            enabled: !authState.isLoading,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Xác thực',
            onPressed: authState.isLoading ? null : _submitForm,
            isLoading: authState.isLoading,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: authState.isLoading ? null : _resendOTP,
            child: const Text('Gửi lại mã OTP'),
          ),
        ],
      ),
    );
  }
}
```

## Xử lý State Management

### 1. Auth Controller

```dart
// lib/features/auth/logic/auth_controller.dart
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState());

  Future<void> sendOTP(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authRepository.sendOTP(phoneNumber);
      state = state.copyWith(
        isLoading: false,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOTP(String otpCode) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authRepository.verifyOTP(otpCode);
      state = state.copyWith(
        isLoading: false,
        isPhoneVerified: true,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState();
  }
}

class AuthState {
  final bool isLoading;
  final String? error;
  final String? phoneNumber;
  final bool isPhoneVerified;
  final User? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.phoneNumber,
    this.isPhoneVerified = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? phoneNumber,
    bool? isPhoneVerified,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      user: user ?? this.user,
    );
  }
}
```

### 2. Registration Controller

```dart
// lib/features/auth/logic/registration_controller.dart
class RegistrationController extends StateNotifier<RegistrationState> {
  final UserRepository _userRepository;

  RegistrationController(this._userRepository) : super(const RegistrationState());

  Future<void> sendOTP(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Send OTP logic here
      state = state.copyWith(
        isLoading: false,
        phoneNumber: phoneNumber,
        currentStep: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOTPAndCreateAccount(String otpCode) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Verify OTP and create account
      final user = UserModel(
        uid: 'generated_uid',
        phoneNumber: state.phoneNumber,
        firstName: state.personalInfo?.firstName,
        lastName: state.personalInfo?.lastName,
        email: state.personalInfo?.email,
        dateOfBirth: state.personalInfo?.dateOfBirth,
        address: state.personalInfo?.address,
        isEmailVerified: false,
        createdAt: DateTime.now(),
      );

      await _userRepository.createUserProfile(user);
      
      state = state.copyWith(
        isLoading: false,
        isRegistered: true,
        currentStep: 3,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void updatePersonalInfo(UserModel personalInfo) {
    state = state.copyWith(
      personalInfo: personalInfo,
      currentStep: 1,
    );
  }
}
```

## Testing và Debugging

### 1. Unit Tests

```dart
// test/features/auth/data/auth_repository_test.dart
void main() {
  group('AuthRepository', () {
    late AuthRepository authRepository;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockSecureStorage = MockFlutterSecureStorage();
      authRepository = AuthRepository(
        firebaseAuth: mockFirebaseAuth,
        secureStorage: mockSecureStorage,
      );
    });

    test('should send OTP successfully', () async {
      // Arrange
      const phoneNumber = '+84901234567';
      when(mockFirebaseAuth.verifyPhoneNumber(
        phoneNumber: any,
        verificationCompleted: any,
        verificationFailed: any,
        codeSent: any,
        codeAutoRetrievalTimeout: any,
        timeout: any,
      )).thenAnswer((_) async {});

      // Act
      await authRepository.sendOTP(phoneNumber);

      // Assert
      verify(mockFirebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: any,
        verificationFailed: any,
        codeSent: any,
        codeAutoRetrievalTimeout: any,
        timeout: any,
      )).called(1);
    });
  });
}
```

### 2. Widget Tests

```dart
// test/features/auth/widgets/phone_input_form_test.dart
void main() {
  group('PhoneInputForm', () {
    testWidgets('should display phone input form', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhoneInputForm(),
            ),
          ),
        ),
      );

      expect(find.text('Số điện thoại'), findsOneWidget);
      expect(find.text('Gửi mã OTP'), findsOneWidget);
    });

    testWidgets('should validate phone number', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhoneInputForm(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Gửi mã OTP'));
      await tester.pump();

      expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    });
  });
}
```

### 3. Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  group('SMS OTP Integration Tests', () {
    testWidgets('complete registration flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to registration
      await tester.tap(find.text('Đăng ký'));
      await tester.pumpAndSettle();

      // Fill personal info
      await tester.enterText(find.byKey(const Key('firstName')), 'John');
      await tester.enterText(find.byKey(const Key('lastName')), 'Doe');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Fill phone number
      await tester.enterText(find.byKey(const Key('phoneNumber')), '+84901234567');
      await tester.tap(find.text('Gửi mã OTP'));
      await tester.pumpAndSettle();

      // Verify OTP
      await tester.enterText(find.byKey(const Key('otpCode')), '123456');
      await tester.tap(find.text('Xác thực'));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Đăng ký thành công'), findsOneWidget);
    });
  });
}
```

## Troubleshooting

### 1. Lỗi thường gặp

#### Firebase không khởi tạo được
```bash
# Giải pháp
flutter clean
flutter pub get
flutter run
```

#### SMS permission bị từ chối
```dart
// Kiểm tra permission
final hasPermission = await SmsPermissionHelper.hasSmsPermissions();
if (!hasPermission) {
  await SmsPermissionHelper.openAppSettings();
}
```

#### OTP không được gửi
- Kiểm tra Firebase Console
- Xác nhận Phone Authentication đã được bật
- Kiểm tra Test Phone Numbers

#### SMS Auto-fill không hoạt động
- Kiểm tra AndroidManifest.xml
- Xác nhận SMS permissions
- Test trên thiết bị thật (không phải emulator)

### 2. Debug Tools

#### Logging
```dart
// Thêm debug logs
print('Sending OTP to: $phoneNumber');
print('Verification ID: $verificationId');
print('OTP Code: $otpCode');
```

#### Firebase Debug
```bash
# Enable Firebase debug logging
flutter run --debug
```

#### Network Inspector
- Sử dụng Android Studio Network Inspector
- Kiểm tra Firebase API calls
- Xem request/response details

### 3. Performance Optimization

#### Lazy Loading
```dart
// Chỉ load khi cần thiết
late final AuthRepository _authRepository;
```

#### Caching
```dart
// Cache verification ID
await _secureStorage.write(
  key: 'verification_id',
  value: verificationId,
);
```

#### Error Handling
```dart
try {
  await _authRepository.sendOTP(phoneNumber);
} catch (e) {
  if (e is FirebaseAuthException) {
    // Handle specific Firebase errors
  } else {
    // Handle generic errors
  }
}
```

## Kết luận

Tài liệu này cung cấp hướng dẫn chi tiết để tích hợp SMS OTP API vào quy trình đăng ký tài khoản. Với các bước được mô tả, bạn có thể:

1. Cấu hình Firebase cho SMS OTP
2. Implement SMS permission handling
3. Tạo UI components cho phone input và OTP verification
4. Xử lý state management với Riverpod
5. Test và debug ứng dụng

Để có thêm thông tin chi tiết, hãy tham khảo:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/docs)
