# Firebase Test Numbers Setup Guide (Vietnamese Numbers)

## 🎯 **Cách sử dụng Firebase Test Numbers với số Việt Nam**

### **1. Thêm Test Numbers vào Firebase Console:**

1. Mở [Firebase Console](https://console.firebase.google.com)
2. Chọn project của bạn
3. Vào **Authentication** > **Sign-in method**
4. Chọn **Phone** provider
5. Scroll xuống phần **Test phone numbers**
6. Thêm các số sau:

```
Phone Number: +84 987 654 321
Verification code: 123456

Phone Number: +84 987 654 322
Verification code: 123456

Phone Number: +84 987 654 323
Verification code: 123456

Phone Number: +84 987 654 324
Verification code: 123456

Phone Number: +84 987 654 325
Verification code: 123456
```

### **2. Cách test trong ứng dụng:**

#### **Registration Flow:**
1. Nhập số điện thoại: `0987654321` hoặc `+84987654321`
2. Nhấn "Gửi mã OTP"
3. Nhập mã OTP: `123456`
4. Nhấn "Xác thực"
5. ✅ Đăng ký thành công!

#### **Login Flow:**
1. Nhập cùng số điện thoại: `0987654321` hoặc `+84987654321`
2. Nhấn "Gửi mã OTP"
3. Nhập mã OTP: `123456`
4. Nhấn "Xác thực"
5. ✅ Đăng nhập thành công!

### **3. Các số test có sẵn:**

```dart
// Các số Firebase Test Numbers Việt Nam được hỗ trợ:
+84987654321  // Test Number 1 (VN)
+84987654322  // Test Number 2 (VN)
+84987654323  // Test Number 3 (VN)
+84987654324  // Test Number 4 (VN)
+84987654325  // Test Number 5 (VN)

// Tất cả đều sử dụng OTP: 123456
```

### **4. Format số điện thoại:**

#### **Cách nhập trong ứng dụng:**
- **Format 1**: `0987654321` (số Việt Nam thông thường)
- **Format 2**: `+84987654321` (format quốc tế)
- **Format 3**: `987654321` (không có mã quốc gia)

#### **Ứng dụng sẽ tự động format thành:**
- `0987654321` → `+84987654321`
- `987654321` → `+84987654321`

### **5. Debug Information:**

Khi sử dụng Firebase Test Numbers Việt Nam, bạn sẽ thấy các log sau:

```
🧪 Debug: Detected Firebase Test Number: +84987654321
📱 Debug: Firebase Test Numbers always use OTP: 123456
✅ Debug: This will work without billing account
```

### **5. Lợi ích:**

- ✅ **Hoàn toàn miễn phí** - Không cần billing account
- ✅ **Không tốn quota** - Unlimited testing
- ✅ **OTP cố định** - Luôn là `123456`
- ✅ **Hoạt động ngay** - Không cần setup phức tạp
- ✅ **Test đầy đủ** - Registration, login, password setup
- ⚠️ **Không gửi SMS thật** - Chỉ là số ảo để test

### **6. Hạn chế:**

- ❌ **Không nhận SMS thật** - Không có tin nhắn gửi về điện thoại
- ❌ **OTP cố định** - Luôn là 123456, không phải OTP thật
- ❌ **Chỉ cho development** - Không phù hợp cho production

### **7. Khi nào cần SMS thật:**

Nếu bạn muốn **nhận SMS thật** về điện thoại, bạn cần:
1. **Upgrade Firebase lên Blaze plan**
2. **Sử dụng số điện thoại thật**
3. **Trả phí ~$0.01/SMS**

📖 **Xem hướng dẫn chi tiết:** `REAL_PHONE_SMS_GUIDE.md`

### **6. Troubleshooting:**

#### **Nếu không nhận được OTP:**
1. Kiểm tra số điện thoại có đúng format không
2. Đảm bảo đã thêm vào Firebase Console
3. Kiểm tra Firebase project settings

#### **Nếu OTP không đúng:**
- Firebase Test Numbers luôn sử dụng OTP: `123456`
- Không cần nhập OTP thật từ SMS

#### **Nếu gặp lỗi verification:**
- Kiểm tra Firebase Console > Authentication > Sign-in method
- Đảm bảo Phone provider đã được enable
- Kiểm tra Test phone numbers đã được thêm

### **7. Production Notes:**

⚠️ **Lưu ý quan trọng:**
- Firebase Test Numbers chỉ hoạt động trong development
- Trong production, bạn cần sử dụng số điện thoại thật
- Để sử dụng số điện thoại thật, cần upgrade lên Blaze plan

### **8. Alternative cho Production:**

Nếu bạn muốn test với số điện thoại thật mà không muốn upgrade Blaze plan:

1. **Sử dụng Firebase Emulator Suite**
2. **Tích hợp Twilio SMS**
3. **Sử dụng AWS SNS**
4. **Tạo mock SMS service**

---

## 🎉 **Kết luận:**

Firebase Test Numbers là giải pháp tốt nhất để test SMS OTP authentication mà không cần billing account. Ứng dụng AuthenX đã được cấu hình để hỗ trợ đầy đủ Firebase Test Numbers!

**Happy Testing!** 🚀📱✨
