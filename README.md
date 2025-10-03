# HOANG TRONG TRA

# AuthenX - SMS OTP Firebase Authentication (Android Only)

Ứng dụng Flutter Android-only demo đăng nhập bằng SMS OTP sử dụng Firebase Authentication với Phone Sign-in (Free Auth Test Numbers).

## 🚀 Tính năng

- ✅ Đăng nhập bằng số điện thoại
- ✅ Xác thực OTP qua SMS
- ✅ SMS Auto-fill (tự động điền mã OTP)
- ✅ Resend OTP với đếm ngược
- ✅ Quản lý state với Riverpod
- ✅ Routing với GoRouter
- ✅ UI/UX hiện đại với Google Fonts
- ✅ Hỗ trợ Test Phone Numbers miễn phí

## 📱 Screenshots

### Màn hình nhập số điện thoại
```
┌─────────────────────────┐
│        🔒 AuthenX       │
│                         │
│   📱 Nhập số điện thoại  │
│                         │
│  [Số điện thoại]        │
│                         │
│    [Gửi mã OTP]         │
│                         │
│ ℹ️ Sử dụng số test để demo│
└─────────────────────────┘
```

### Màn hình xác thực OTP
```
┌─────────────────────────┐
│     📱 Xác thực OTP     │
│                         │
│   Nhập mã 6 chữ số      │
│   đã được gửi đến       │
│   +84901234567          │
│                         │
│    [0 0 0 0 0 0]        │
│                         │
│    [Xác thực]           │
│                         │
│    Không nhận được mã?   │
│    [Gửi lại]            │
└─────────────────────────┘
```

### Màn hình Profile
```
┌─────────────────────────┐
│       👤 Hồ sơ          │
│                         │
│        Chào mừng!        │
│   Bạn đã đăng nhập       │
│      thành công          │
│                         │
│ ┌─────────────────────┐ │
│ │ Thông tin tài khoản │ │
│ │                     │ │
│ │ 🆔 User ID: abc123   │ │
│ │ 📱 SĐT: +84901234567│ │
│ │ 📧 Email: Không có   │ │
│ │ ✅ Email đã xác thực │ │
│ │ 🕐 Ngày tạo: 1/1/24  │ │
│ │ 🔑 Lần đăng nhập cuối│ │
│ └─────────────────────┘ │
│                         │
│      [Đăng xuất]         │
└─────────────────────────┘
```

## 🛠️ Cài đặt và Chạy

### 1. Yêu cầu hệ thống
- Flutter 3.x
- Dart 3.x
- Android Studio / VS Code
- Android SDK (minSdkVersion 21+)
- **Chỉ hỗ trợ Android** (iOS, Web, Desktop đã được loại bỏ)

### 2. Clone và cài đặt dependencies
```bash
git clone <repository-url>
cd authen_x
flutter clean
flutter pub get
```

### 3. Cấu hình Firebase

#### Bước 1: Tạo Firebase Project
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới với tên "AuthenX Demo"
3. Chọn "Enable Google Analytics" (tùy chọn)

#### Bước 2: Thêm Android App
1. Trong Firebase Console, click "Add app" → Android
2. Nhập package name: `com.example.authen_x`
3. Tải file `google-services.json`
4. Đặt file vào thư mục `android/app/`

#### Bước 3: Bật Phone Authentication
1. Trong Firebase Console, vào "Authentication"
2. Chọn tab "Sign-in method"
3. Bật "Phone" provider
4. Thêm Test Phone Numbers:
   - Phone number: `+84901234567`
   - Verification code: `123456`
   - Phone number: `+84987654321`
   - Verification code: `654321`

#### Bước 4: Cấu hình Android
File `android/app/google-services.json` đã được cấu hình với Firebase project thật:
- **Project ID**: `authen-x-3215b`
- **Project Number**: `830604884407`
- **Package Name**: `com.example.authen_x`

### 4. Chạy ứng dụng
```bash
flutter run
```

## 📱 Sử dụng Test Phone Numbers

Ứng dụng đã được cấu hình với các số điện thoại test miễn phí:

| Số điện thoại | Mã OTP | Mô tả |
|---------------|--------|-------|
| +84901234567  | 123456 | Số test chính |
| +84987654321  | 654321 | Số test phụ |
| 0901234567    | 123456 | Format Việt Nam |

### Lưu ý về SMS Auto-fill:
- **Emulator**: SMS auto-fill có thể không hoạt động
- **Thiết bị thật**: SMS auto-fill sẽ hoạt động tự động
- **Test numbers**: Luôn sử dụng mã OTP cố định (123456 hoặc 654321)

## 🏗️ Cấu trúc Project

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # App configuration
├── router/
│   └── app_router.dart       # GoRouter configuration
├── features/auth/
│   ├── data/
│   │   └── auth_repository.dart    # Firebase Auth logic
│   ├── logic/
│   │   └── auth_controller.dart    # Riverpod state management
│   ├── widgets/
│   │   ├── phone_input_form.dart  # Phone input UI
│   │   └── otp_input_form.dart    # OTP input UI
│   └── pages/
│       ├── phone_signin_page.dart # Phone sign-in page
│       ├── otp_verify_page.dart   # OTP verification page
│       └── profile_page.dart      # User profile page
└── common/
    ├── widgets/
    │   ├── app_button.dart        # Custom button widget
    │   └── app_text_field.dart    # Custom text field widget
    ├── utils/
    │   └── validators.dart        # Form validation
    └── theme/
        └── app_theme.dart         # App theme configuration
```

## 🔧 Dependencies

```yaml
dependencies:
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  
  # SMS and security
  sms_autofill: ^2.3.0
  flutter_secure_storage: ^9.2.2
  
  # State management and routing
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  
  # UI and utilities
  intl: ^0.19.0
  google_fonts: ^6.2.1
```

## 🎨 UI/UX Features

- **Material Design 3**: Sử dụng Material You design system
- **Google Fonts**: Typography với Inter font
- **Responsive Design**: Tối ưu cho mọi kích thước màn hình
- **Dark/Light Theme**: Hỗ trợ cả hai chế độ sáng/tối
- **Loading States**: Hiển thị trạng thái loading cho các action
- **Error Handling**: Snackbar thông báo lỗi
- **Form Validation**: Validation real-time cho input

## 🔐 Bảo mật

- **Secure Storage**: Lưu trữ dữ liệu nhạy cảm với Flutter Secure Storage
- **Phone Verification**: Xác thực số điện thoại qua Firebase
- **OTP Security**: Mã OTP có thời hạn và chỉ sử dụng một lần
- **Auto Sign-out**: Tự động đăng xuất khi token hết hạn

## 🐛 Troubleshooting

### Lỗi Firebase không khởi tạo được
```bash
flutter clean
flutter pub get
flutter run
```

### Lỗi SMS auto-fill không hoạt động
- Kiểm tra quyền SMS trên thiết bị
- Đảm bảo sử dụng thiết bị thật (không phải emulator)
- Kiểm tra format số điện thoại (+84...)

### Lỗi build Android
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## 📄 License

MIT License - Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## 🤝 Contributing

1. Fork project
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 📞 Support

Nếu gặp vấn đề, hãy tạo issue trên GitHub hoặc liên hệ qua email.

---

**AuthenX** - SMS OTP Authentication với Firebase 🔐📱

**trahoangdev** **jameshoang**
