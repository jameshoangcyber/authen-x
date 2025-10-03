import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/utils/validators.dart';
import '../../../common/utils/sms_permission_helper.dart';
import '../logic/registration_controller.dart';

class RegistrationVerifyPage extends ConsumerStatefulWidget {
  const RegistrationVerifyPage({super.key});

  @override
  ConsumerState<RegistrationVerifyPage> createState() =>
      _RegistrationVerifyPageState();
}

class _RegistrationVerifyPageState
    extends ConsumerState<RegistrationVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
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
      // Check if we have all necessary permissions
      final hasAllPermissions =
          await SmsPermissionHelper.hasAllSmsPermissions();

      if (!hasAllPermissions) {
        // Request all permissions at once
        final results = await SmsPermissionHelper.requestAllSmsPermissions();

        // Check if SMS permission was granted
        if (!results['sms']!) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cần quyền đọc SMS để tự động điền mã OTP'),
                action: SnackBarAction(
                  label: 'Cài đặt',
                  onPressed: () => SmsPermissionHelper.openAppSettings(),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        // Show additional info for other permissions
        if (!results['phone']! || !results['notification']!) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Một số quyền bổ sung có thể cần thiết cho SMS autofill',
                ),
                duration: Duration(seconds: 3),
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
      // SMS autofill not available
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final otpCode = _otpController.text.trim();
      print('🔍 Debug: Submitting OTP form with code: $otpCode');
      ref
          .read(registrationControllerProvider.notifier)
          .verifyOTPAndCompleteRegistration(otpCode);
    }
  }

  void _resendOTP() {
    ref.read(registrationControllerProvider.notifier).resendOTP();
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationControllerProvider);

    // Listen for OTP verification completion
    ref.listen<RegistrationState>(registrationControllerProvider, (
      previous,
      next,
    ) {
      print(
        '🔄 Debug: RegistrationState in verify page - currentStep: ${next.currentStep}, isPhoneVerified: ${next.isPhoneVerified}, isLoading: ${next.isLoading}',
      );
      print(
        '🔍 Debug: Checking navigation condition - currentStep == 4: ${next.currentStep == 4}, !isLoading: ${!next.isLoading}',
      );
      if (next.currentStep == 4 && !next.isLoading) {
        print('🚀 Debug: Registration completed, navigating to sign in');
        // Show success message and navigate to sign in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Reset state
          ref.read(registrationControllerProvider.notifier).resetState();
          context.go('/phone-signin');
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực OTP'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/phone-registration'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Progress indicator
                Row(
                  children: [
                    _buildProgressStep(1, 'Thông tin', true),
                    Expanded(child: _buildProgressLine(true)),
                    _buildProgressStep(2, 'Số điện thoại', true),
                    Expanded(child: _buildProgressLine(true)),
                    _buildProgressStep(3, 'Xác thực', true),
                  ],
                ),

                const SizedBox(height: 40),

                // OTP icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.sms,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  'Bước 3: Xác thực OTP',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Nhập mã 6 chữ số đã được gửi đến',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                Text(
                  registrationState.phoneNumber ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // OTP input form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        label: 'Mã OTP',
                        hint: '000000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: Validators.otp,
                        enabled: !registrationState.isLoading,
                        onChanged: (value) {
                          if (value.length == 6) {
                            _submitForm();
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Verify button
                      AppButton(
                        text: 'Xác thực',
                        onPressed: registrationState.isLoading
                            ? null
                            : _submitForm,
                        isLoading: registrationState.isLoading,
                        icon: Icons.verified_user,
                      ),

                      const SizedBox(height: 16),

                      // Resend button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Không nhận được mã? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: registrationState.isLoading
                                ? null
                                : _resendOTP,
                            child: const Text('Gửi lại'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Error message
                if (registrationState.error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            registrationState.error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(registrationControllerProvider.notifier)
                                .clearError();
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.red[700],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Back button
                TextButton.icon(
                  onPressed: () => context.go('/personal-info'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                ),

                const SizedBox(height: 16),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sử dụng mã OTP để xác thực tài khoản.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isCompleted ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isCompleted
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Container(
      height: 2,
      color: isCompleted
          ? Theme.of(context).colorScheme.primary
          : Colors.grey[300],
    );
  }
}
