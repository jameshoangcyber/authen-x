# AuthenX - SMS OTP Firebase Authentication Documentation

## Tổng quan dự án

AuthenX là một ứng dụng Flutter Android-only được thiết kế để demo tính năng xác thực SMS OTP sử dụng Firebase Authentication. Ứng dụng cung cấp giao diện đăng nhập/đăng ký hiện đại với khả năng tự động điền mã OTP từ tin nhắn SMS.

## Thông tin cơ bản

- **Tên dự án**: AuthenX
- **Platform**: Android Only
- **Framework**: Flutter 3.x
- **Ngôn ngữ**: Dart 3.x
- **Backend**: Firebase (Authentication + Firestore)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **UI Framework**: Material Design 3

## Kiến trúc hệ thống

### Cấu trúc thư mục

```
lib/
├── main.dart                     # Entry point của ứng dụng
├── app.dart                      # Cấu hình MaterialApp và theme
├── router/
│   └── app_router.dart          # Cấu hình navigation với GoRouter
├── common/                       # Shared components và utilities
│   ├── theme/
│   │   └── app_theme.dart       # Theme configuration (Light/Dark)
│   ├── utils/
│   │   ├── validators.dart      # Form validation utilities
│   │   └── sms_permission_helper.dart # SMS permission management
│   └── widgets/
│       ├── app_button.dart      # Custom button component
│       └── app_text_field.dart  # Custom text field component
├── features/                     # Feature-based architecture
│   ├── auth/                     # Authentication feature
│   │   ├── data/                # Data layer
│   │   │   ├── auth_repository.dart    # Firebase Auth operations
│   │   │   └── user_repository.dart    # Firestore user operations
│   │   ├── logic/               # Business logic layer
│   │   │   ├── auth_controller.dart    # Auth state management
│   │   │   └── registration_controller.dart # Registration flow
│   │   ├── models/              # Data models
│   │   │   └── user_model.dart  # User data model
│   │   ├── pages/               # UI pages
│   │   │   ├── auth_method_page.dart      # Login method selection
│   │   │   ├── auth_method_register_page.dart # Register method selection
│   │   │   ├── phone_signin_page.dart     # Phone number input
│   │   │   ├── otp_verify_page.dart       # OTP verification
│   │   │   ├── phone_registration_page.dart # Phone registration
│   │   │   ├── personal_info_page.dart    # Personal info input
│   │   │   ├── registration_verify_page.dart # Registration OTP
│   │   │   ├── email_signin_page.dart     # Email sign-in
│   │   │   ├── email_registration_page.dart # Email registration
│   │   │   └── profile_page.dart          # User profile
│   │   └── widgets/             # Auth-specific widgets
│   │       ├── phone_input_form.dart      # Phone input form
│   │       └── otp_input_form.dart        # OTP input form
│   └── splash/                  # Splash screen feature
│       ├── logic/
│       │   └── splash_controller.dart    # Splash navigation logic
│       └── pages/
│           └── splash_page.dart         # Splash screen UI
└── test/
    └── widget_test.dart         # Unit tests
```

### Kiến trúc MVVM + Repository Pattern

```
UI Layer (Pages/Widgets)
    ↓
Business Logic Layer (Controllers)
    ↓
Data Layer (Repositories)
    ↓
External Services (Firebase)
```

## Tính năng chính

### 1. Đa phương thức xác thực

#### SMS OTP Authentication
- Nhập số điện thoại
- Gửi mã OTP qua SMS
- Tự động điền mã OTP từ tin nhắn
- Resend OTP với đếm ngược
- Xác thực và đăng nhập

#### Email/Password Authentication
- Đăng ký tài khoản với email
- Đăng nhập với email và mật khẩu
- Xác thực email
- Reset mật khẩu

### 2. Quy trình đăng ký

#### SMS Registration Flow
1. Chọn phương thức đăng ký (SMS OTP)
2. Nhập thông tin cá nhân (Họ tên, email, ngày sinh, địa chỉ)
3. Nhập số điện thoại
4. Xác thực OTP
5. Hoàn tất đăng ký và chuyển về trang đăng nhập

#### Email Registration Flow
1. Chọn phương thức đăng ký (Email)
2. Nhập thông tin cá nhân và mật khẩu
3. Xác thực email
4. Hoàn tất đăng ký và chuyển về trang đăng nhập

### 3. Quản lý người dùng

#### User Profile
- Hiển thị thông tin cá nhân
- Quản lý trạng thái đăng nhập
- Đăng xuất
- Cập nhật thông tin

#### Data Storage
- Lưu trữ thông tin người dùng trong Firestore
- Secure storage cho dữ liệu nhạy cảm
- Real-time sync với Firebase

## Công nghệ sử dụng

### Frontend
- **Flutter**: Framework chính
- **Dart**: Ngôn ngữ lập trình
- **Material Design 3**: Design system
- **Google Fonts**: Typography (Inter font)
- **Riverpod**: State management
- **GoRouter**: Navigation

### Backend & Services
- **Firebase Authentication**: Xác thực người dùng
- **Cloud Firestore**: Database
- **Firebase Phone Auth**: SMS OTP
- **Firebase Email Auth**: Email/Password

### Android Specific
- **SMS Autofill**: Tự động điền OTP
- **Permission Handler**: Quản lý quyền
- **Secure Storage**: Lưu trữ an toàn

## Cấu hình Firebase

### 1. Firebase Project Setup
- Project ID: `authen-x-3215b`
- Project Number: `830604884407`
- Package Name: `com.example.authen_x`

### 2. Authentication Methods
- Phone Authentication (SMS OTP)
- Email/Password Authentication
- Test Phone Numbers được cấu hình

### 3. Firestore Database
- Collection: `users`
- Security Rules: Chỉ cho phép authenticated users
- Real-time sync với client

## Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.8
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.3
  
  # SMS & Security
  sms_autofill: ^2.3.0
  flutter_secure_storage: ^9.2.2
  permission_handler: ^11.3.1
  
  # State Management & Routing
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  
  # UI & Utils
  intl: ^0.19.0
  google_fonts: ^6.2.1
```

### Dev Dependencies
```yaml
dev_dependencies:
  flutter_test: sdk: flutter
  flutter_lints: ^5.0.0
```

## Cấu hình Android

### 1. AndroidManifest.xml
```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- SMS Receiver for OTP autofill -->
<receiver
    android:name="com.jaumard.smsautofill.SmsReceiver"
    android:exported="true">
    <intent-filter android:priority="1000">
        <action android:name="android.provider.Telephony.SMS_RECEIVED" />
    </intent-filter>
</receiver>
```

### 2. Build Configuration
- minSdkVersion: 21
- targetSdkVersion: Flutter default
- Google Services plugin enabled

## State Management

### Riverpod Providers

#### Authentication State
```dart
// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

// OTP verification controller
final otpVerificationControllerProvider = 
    StateNotifierProvider<OtpVerificationController, OtpVerificationState>((ref) {
  return OtpVerificationController(ref.read(authRepositoryProvider));
});

// Email sign-in controller
final emailSignInControllerProvider = 
    StateNotifierProvider<EmailSignInController, EmailSignInState>((ref) {
  return EmailSignInController(ref.read(authRepositoryProvider));
});
```

#### Registration State
```dart
// Registration flow controller
final registrationControllerProvider = 
    StateNotifierProvider<RegistrationController, RegistrationState>((ref) {
  return RegistrationController(ref.read(userRepositoryProvider));
});
```

## Navigation Flow

### Route Structure
```
/splash
├── /auth-method (Login method selection)
│   ├── /phone-signin (Phone number input)
│   │   └── /otp-verify (OTP verification)
│   └── /email-signin (Email sign-in)
├── /auth-method-register (Register method selection)
│   ├── /personal-info (Personal info input)
│   │   └── /phone-registration (Phone number input)
│   │       └── /registration-verify (Registration OTP)
│   └── /email-registration (Email registration)
└── /profile (User profile)
```

### Navigation Logic
- Splash screen kiểm tra authentication state
- Redirect đến login nếu chưa đăng nhập
- Redirect đến profile nếu đã đăng nhập
- Error handling với custom error page

## Data Models

### UserModel
```dart
class UserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? address;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
}
```

### Authentication States
```dart
// OTP Verification State
class OtpVerificationState {
  final bool isLoading;
  final String? error;
  final String? phoneNumber;
  final bool isPhoneVerified;
}

// Registration State
class RegistrationState {
  final int currentStep;
  final bool isLoading;
  final String? error;
  final String? phoneNumber;
  final bool isPhoneVerified;
  final UserModel? personalInfo;
  final bool isRegistered;
}
```

## Security Features

### 1. SMS OTP Security
- Mã OTP 6 chữ số
- Thời hạn có giới hạn
- Chỉ sử dụng một lần
- Auto-fill từ tin nhắn SMS

### 2. Data Protection
- Secure storage cho sensitive data
- Firestore security rules
- Input validation và sanitization

### 3. Permission Management
- Runtime permission requests
- Graceful fallback khi không có quyền
- User-friendly permission dialogs

## Error Handling

### 1. Authentication Errors
- Invalid phone number format
- OTP verification failed
- Network connectivity issues
- Firebase service errors

### 2. UI Error States
- Loading states với progress indicators
- Error messages với SnackBar
- Retry mechanisms
- Graceful degradation

### 3. Form Validation
- Real-time validation
- Required field checking
- Format validation (phone, email)
- Password strength requirements

## Testing

### 1. Unit Tests
- Widget tests cho UI components
- Unit tests cho business logic
- Mock Firebase services

### 2. Integration Tests
- End-to-end authentication flow
- Navigation testing
- State management testing

### 3. Test Data
- Firebase Test Phone Numbers
- Mock user data
- Test scenarios

## Performance Optimization

### 1. State Management
- Efficient provider usage
- Minimal rebuilds
- Proper disposal of resources

### 2. UI Optimization
- Lazy loading
- Efficient list rendering
- Image optimization

### 3. Network Optimization
- Caching strategies
- Offline support
- Error retry logic

## Deployment

### 1. Android Build
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

### 2. Firebase Configuration
- google-services.json đã được cấu hình
- Firestore rules đã được setup
- Authentication providers enabled

### 3. App Signing
- Debug keystore cho development
- Release keystore cho production

## Troubleshooting

### 1. Common Issues
- Firebase initialization errors
- SMS permission denied
- OTP not received
- Navigation issues

### 2. Debug Steps
- Check Firebase configuration
- Verify Android permissions
- Check network connectivity
- Review console logs

### 3. Solutions
- Clean and rebuild project
- Reset Firebase configuration
- Check device permissions
- Update dependencies

## Future Enhancements

### 1. Planned Features
- Biometric authentication
- Social login integration
- Push notifications
- Offline mode

### 2. Technical Improvements
- Performance optimization
- Better error handling
- Enhanced security
- Code refactoring

### 3. UI/UX Improvements
- Dark mode optimization
- Accessibility features
- Animation enhancements
- Responsive design

## Contributing

### 1. Development Setup
- Clone repository
- Install Flutter dependencies
- Configure Firebase
- Run on Android device/emulator

### 2. Code Standards
- Follow Dart/Flutter conventions
- Use meaningful variable names
- Add proper documentation
- Write unit tests

### 3. Pull Request Process
- Create feature branch
- Implement changes
- Add tests
- Submit pull request

## License

MIT License - Xem file LICENSE để biết thêm chi tiết.

## Support

Nếu gặp vấn đề, hãy tạo issue trên GitHub hoặc liên hệ qua email.

---

**AuthenX** - SMS OTP Authentication với Firebase

**Developer**: HOANG TRONG TRA
**GitHub**: trahoangdev
