class Validators {
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    // Remove all non-digit characters
    final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.length < 10) {
      return 'Số điện thoại phải có ít nhất 10 chữ số';
    }

    if (cleanNumber.length > 15) {
      return 'Số điện thoại không được quá 15 chữ số';
    }

    // Check if it starts with a valid country code or local number
    if (!cleanNumber.startsWith('84') && !cleanNumber.startsWith('0')) {
      return 'Số điện thoại không hợp lệ';
    }

    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mã OTP';
    }

    if (value.length != 6) {
      return 'Mã OTP phải có 6 chữ số';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Mã OTP chỉ được chứa số';
    }

    return null;
  }

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }

    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    if (value.length > 128) {
      return 'Mật khẩu không được quá 128 ký tự';
    }

    // Check for at least one letter and one number
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất một chữ cái và một số';
    }

    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }

    return null;
  }
}
