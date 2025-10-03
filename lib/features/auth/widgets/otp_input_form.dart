import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/utils/validators.dart';
import '../../../common/utils/sms_permission_helper.dart';
import '../logic/auth_controller.dart';

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
    // Delay the provider modification to avoid lifecycle issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(otpVerificationControllerProvider.notifier)
          .setPhoneNumber(widget.phoneNumber);

      // Listen for authentication success after widget is initialized
      ref.listen<OtpVerificationState>(otpVerificationControllerProvider, (
        previous,
        next,
      ) {
        if (next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          // Delay the provider modification to avoid lifecycle issues
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(otpVerificationControllerProvider.notifier).clearError();
          });
        }
      });
    });
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
      ref.read(otpVerificationControllerProvider.notifier).verifyOTP(otpCode);
    }
  }

  void _resendOTP() {
    ref.read(otpVerificationControllerProvider.notifier).resendOTP();
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpVerificationControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),

          // Title
          Text(
            'Xác thực mã OTP',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
            widget.phoneNumber,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // OTP input field
          TextFormField(
            controller: _otpController,
            validator: Validators.otp,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
            ),
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
            onPressed: otpState.isLoading ? null : _submitForm,
            isLoading: otpState.isLoading,
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
              if (otpState.resendCountdown > 0)
                Text(
                  'Gửi lại sau ${otpState.resendCountdown}s',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                )
              else
                TextButton(
                  onPressed: otpState.isResending ? null : _resendOTP,
                  child: otpState.isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi lại'),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Back button
          TextButton.icon(
            onPressed: () => context.go('/phone-signin'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
          ),

          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sử dụng mã OTP bạn vừa nhận để xác thực tài khoản.',
                    style: TextStyle(color: Colors.orange[700], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
