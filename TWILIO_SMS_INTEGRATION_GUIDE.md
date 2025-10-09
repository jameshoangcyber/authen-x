# Twilio SMS Integration Guide for AuthenX

## 🎯 **Tổng quan về Twilio SMS**

### **Lợi ích của Twilio:**
- ✅ **SMS thật** - Gửi tin nhắn đến số điện thoại thật
- ✅ **Giá rẻ** - Chỉ ~$0.0075/SMS (~180 VND)
- ✅ **Không cần Firebase billing** - Hoạt động độc lập
- ✅ **Reliable** - Uptime 99.95%
- ✅ **Global coverage** - Hỗ trợ 200+ quốc gia
- ✅ **Easy integration** - API đơn giản

### **So sánh chi phí:**
| Provider | Cost/SMS | VND/SMS | Notes |
|----------|----------|---------|-------|
| Firebase | $0.01 | ~240 VND | Cần Blaze plan |
| Twilio | $0.0075 | ~180 VND | Rẻ hơn 25% |
| AWS SNS | $0.0075 | ~180 VND | Tương đương Twilio |

---

## 🚀 **Bước 1: Tạo Twilio Account**

### **1.1 Đăng ký Twilio:**
1. Truy cập [Twilio Console](https://console.twilio.com/)
2. Nhấn **"Sign up"**
3. Điền thông tin:
   - Email
   - Password
   - Phone number (để verify)
4. Verify phone number qua SMS
5. ✅ Account được tạo thành công!

### **1.2 Lấy Credentials:**
1. Vào **Console Dashboard**
2. Tìm **Account Info** section
3. Copy các thông tin sau:
   ```
   Account SID: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Auth Token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Phone Number: +1234567890 (Twilio phone number)
   ```

### **1.3 Add Credit:**
1. Vào **Billing** > **Payment Methods**
2. Thêm thẻ tín dụng
3. Add $20 credit (đủ cho ~2,600 SMS)
4. ✅ Ready to send SMS!

---

## 🔧 **Bước 2: Cài đặt Dependencies**

### **2.1 Thêm vào pubspec.yaml:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Twilio SMS
  twilio_flutter: ^0.3.0
  
  # HTTP requests
  http: ^1.1.0
  
  # Environment variables
  flutter_dotenv: ^5.1.0
```

### **2.2 Tạo file .env:**
```bash
# Twilio Credentials
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+1234567890
```

### **2.3 Cập nhật .gitignore:**
```gitignore
# Environment variables
.env
.env.local
.env.*.local
```

---

## 📱 **Bước 3: Tạo Twilio SMS Service**

### **3.1 Tạo TwilioService:**
```dart
// lib/services/twilio_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TwilioService {
  static const String _baseUrl = 'https://api.twilio.com/2010-04-01';
  
  String get _accountSid => dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
  String get _authToken => dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
  String get _phoneNumber => dotenv.env['TWILIO_PHONE_NUMBER'] ?? '';
  
  // Send SMS
  Future<bool> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Messages.json');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${_getBasicAuth()}',
        },
        body: {
          'From': _phoneNumber,
          'To': to,
          'Body': message,
        },
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ SMS sent successfully: ${data['sid']}');
        return true;
      } else {
        print('❌ SMS failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ SMS error: $e');
      return false;
    }
  }
  
  // Generate OTP
  String generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 900000 + 100000).toString(); // 6-digit OTP
  }
  
  // Basic Auth for Twilio API
  String _getBasicAuth() {
    final credentials = '$_accountSid:$_authToken';
    return base64Encode(utf8.encode(credentials));
  }
}
```

### **3.2 Cập nhật main.dart:**
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(const AuthenXApp());
}
```

---

## 🔐 **Bước 4: Tích hợp vào AuthRepository**

### **4.1 Cập nhật AuthRepository:**
```dart
// lib/features/auth/data/auth_repository.dart
import '../services/twilio_service.dart';

class AuthRepository {
  final TwilioService _twilioService = TwilioService();
  
  // Send OTP via Twilio SMS
  Future<void> sendOTPViaTwilio(String phoneNumber) async {
    try {
      // Format phone number
      String formattedPhoneNumber = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedPhoneNumber = '+84${phoneNumber.substring(1)}';
      } else if (!phoneNumber.startsWith('+')) {
        formattedPhoneNumber = '+84$phoneNumber';
      }
      
      // Generate OTP
      final otp = _twilioService.generateOTP();
      
      // Store OTP for verification
      await _secureStorage.write(key: 'twilio_otp', value: otp);
      await _secureStorage.write(key: 'twilio_phone', value: formattedPhoneNumber);
      
      // Send SMS
      final message = 'Mã xác thực AuthenX: $otp. Mã có hiệu lực trong 5 phút.';
      final success = await _twilioService.sendSMS(
        to: formattedPhoneNumber,
        message: message,
      );
      
      if (success) {
        print('✅ Twilio SMS sent to: $formattedPhoneNumber');
      } else {
        throw AuthException('Không thể gửi SMS. Vui lòng thử lại.');
      }
    } catch (e) {
      print('❌ Twilio SMS error: $e');
      throw AuthException('Lỗi gửi SMS: $e');
    }
  }
  
  // Verify Twilio OTP
  Future<UserCredential> verifyTwilioOTP(String otpCode) async {
    try {
      final storedOTP = await _secureStorage.read(key: 'twilio_otp');
      final storedPhone = await _secureStorage.read(key: 'twilio_phone');
      
      if (storedOTP == null || storedPhone == null) {
        throw AuthException('Không tìm thấy mã OTP. Vui lòng gửi lại.');
      }
      
      if (storedOTP != otpCode) {
        throw AuthException('Mã OTP không đúng. Vui lòng kiểm tra lại.');
      }
      
      // Create Firebase user with phone number
      final credential = PhoneAuthProvider.credential(
        verificationId: 'twilio_verification',
        smsCode: otpCode,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      // Clean up stored OTP
      await _secureStorage.delete(key: 'twilio_otp');
      await _secureStorage.delete(key: 'twilio_phone');
      
      return userCredential;
    } catch (e) {
      print('❌ Twilio OTP verification error: $e');
      throw AuthException('Lỗi xác thực OTP: $e');
    }
  }
}
```

---

## 🎨 **Bước 5: Cập nhật UI**

### **5.1 Thêm Twilio Option vào PhoneSignInPage:**
```dart
// lib/features/auth/pages/phone_signin_page.dart
class PhoneSignInPage extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ... existing code ...
              
              // Twilio SMS Option
              const SizedBox(height: 24),
              const Text(
                'Hoặc sử dụng SMS thật',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              AppButton(
                text: 'Gửi SMS qua Twilio',
                onPressed: () => _sendTwilioSMS(),
                backgroundColor: Colors.green,
              ),
              
              // ... existing code ...
            ],
          ),
        ),
      ),
    );
  }
  
  void _sendTwilioSMS() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }
    
    try {
      await ref.read(authRepositoryProvider).sendOTPViaTwilio(_phoneController.text);
      
      // Navigate to OTP verification
      context.push('/otp-verify-twilio');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}
```

### **5.2 Tạo TwilioOTPVerifyPage:**
```dart
// lib/features/auth/pages/twilio_otp_verify_page.dart
class TwilioOTPVerifyPage extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực SMS'),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                'Nhập mã OTP đã gửi về điện thoại',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              
              AppTextField(
                controller: _otpController,
                label: 'Mã OTP',
                hint: 'Nhập 6 số',
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              
              const SizedBox(height: 24),
              
              AppButton(
                text: 'Xác thực',
                onPressed: _verifyOTP,
                isLoading: isLoading,
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: _resendOTP,
                child: const Text('Gửi lại mã'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 số')),
      );
      return;
    }
    
    try {
      setState(() => isLoading = true);
      
      await ref.read(authRepositoryProvider).verifyTwilioOTP(_otpController.text);
      
      // Navigate to profile
      context.go('/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
```

---

## 🛣️ **Bước 6: Cập nhật Router**

### **6.1 Thêm route cho Twilio:**
```dart
// lib/router/app_router.dart
final appRouter = GoRouter(
  routes: [
    // ... existing routes ...
    
    GoRoute(
      path: '/otp-verify-twilio',
      builder: (context, state) => const TwilioOTPVerifyPage(),
    ),
  ],
);
```

---

## 💰 **Bước 7: Pricing và Billing**

### **7.1 Twilio Pricing:**
```
Vietnam SMS: $0.0075 per SMS (~180 VND)
US SMS: $0.0075 per SMS
EU SMS: $0.0075 per SMS

Free Trial: $15 credit (2,000 SMS)
```

### **7.2 Cost Calculator:**
```
100 SMS = $0.75 (~18,000 VND)
1,000 SMS = $7.50 (~180,000 VND)
10,000 SMS = $75 (~1,800,000 VND)
```

### **7.3 Billing Alerts:**
1. Vào Twilio Console > Billing
2. Set up Usage Alerts
3. Get notified when approaching limits

---

## 🧪 **Bước 8: Testing**

### **8.1 Test với số thật:**
```dart
// Test function
void testTwilioSMS() async {
  final twilioService = TwilioService();
  
  final success = await twilioService.sendSMS(
    to: '+84987654321', // Your real phone number
    message: 'Test SMS from AuthenX: 123456',
  );
  
  print('SMS sent: $success');
}
```

### **8.2 Test với số test:**
```dart
// Test với Twilio test numbers
final testNumbers = [
  '+15005550006', // Twilio test number
  '+15005550007', // Twilio test number
];
```

---

## 🔒 **Bước 9: Security Best Practices**

### **9.1 Environment Variables:**
```dart
// Never hardcode credentials
// Use .env file instead
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+1234567890
```

### **9.2 OTP Expiration:**
```dart
// Store OTP with timestamp
final otpData = {
  'code': otp,
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'expires': DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch,
};
```

### **9.3 Rate Limiting:**
```dart
// Limit SMS per phone number
final lastSMS = await _secureStorage.read(key: 'last_sms_$phoneNumber');
if (lastSMS != null) {
  final lastTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lastSMS));
  if (DateTime.now().difference(lastTime).inMinutes < 1) {
    throw AuthException('Vui lòng đợi 1 phút trước khi gửi lại SMS');
  }
}
```

---

## 🚀 **Bước 10: Deployment**

### **10.1 Production Setup:**
1. **Buy Twilio phone number** for your country
2. **Set up webhook** for delivery status
3. **Configure monitoring** and alerts
4. **Test thoroughly** before going live

### **10.2 Environment Variables:**
```bash
# Production .env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+84987654321
```

---

## 📊 **Monitoring và Analytics**

### **11.1 Twilio Console:**
- **Message Logs** - Track all SMS sent
- **Delivery Status** - See if SMS delivered
- **Error Logs** - Debug failed messages
- **Usage Analytics** - Monitor costs

### **11.2 App Analytics:**
```dart
// Track SMS usage
void trackSMSSent(String phoneNumber) {
  // Send to analytics service
  analytics.track('sms_sent', {
    'phone_number': phoneNumber,
    'timestamp': DateTime.now().toIso8601String(),
  });
}
```

---

## 🎉 **Kết luận**

### **Lợi ích của Twilio Integration:**
- ✅ **SMS thật** - Gửi đến số điện thoại thật
- ✅ **Giá rẻ** - Rẻ hơn Firebase 25%
- ✅ **Không cần Firebase billing** - Hoạt động độc lập
- ✅ **Reliable** - Uptime cao
- ✅ **Easy integration** - API đơn giản
- ✅ **Global coverage** - Hỗ trợ nhiều quốc gia

### **Khi nào sử dụng:**
- 🎯 **Production apps** - Cần SMS thật
- 🎯 **Cost optimization** - Muốn tiết kiệm chi phí
- 🎯 **Firebase billing issues** - Gặp vấn đề với Firebase billing
- 🎯 **Global apps** - Cần hỗ trợ nhiều quốc gia

**Twilio SMS integration sẽ giúp AuthenX gửi SMS thật một cách đáng tin cậy và tiết kiệm chi phí!** 🚀📱✨
