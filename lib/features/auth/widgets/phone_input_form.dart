import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/utils/validators.dart';
import '../logic/auth_controller.dart';

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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = _phoneController.text.trim();
      ref.read(phoneSignInControllerProvider.notifier).sendOTP(phoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneSignInState = ref.watch(phoneSignInControllerProvider);

    // Listen for OTP sent state changes
    ref.listen<PhoneSignInState>(phoneSignInControllerProvider, (
      previous,
      next,
    ) {
      print(
        '🔄 Debug: PhoneSignInState changed - otpSent: ${next.otpSent}, phoneNumber: ${next.phoneNumber}',
      );

      if (next.otpSent && next.phoneNumber != null) {
        print(
          '🚀 Debug: Navigating to OTP verify page with phone: ${next.phoneNumber}',
        );
        // Navigate to OTP verification page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/otp-verify', extra: next.phoneNumber);
        });
      }

      if (next.error != null) {
        print('❌ Debug: Error in PhoneSignInState: ${next.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Delay the provider modification to avoid lifecycle issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(phoneSignInControllerProvider.notifier).clearError();
        });
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),

          // Title
          Text(
            'Đăng nhập bằng số điện thoại',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Nhập số điện thoại để nhận mã xác thực',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Phone input field
          AppTextField(
            controller: _phoneController,
            label: 'Số điện thoại',
            hint: 'Nhập số điện thoại của bạn',
            keyboardType: TextInputType.phone,
            validator: Validators.phoneNumber,
            prefixIcon: const Icon(Icons.phone),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            focusNode: _focusNode,
            onChanged: (value) {
              // Auto format phone number
              if (value.isNotEmpty &&
                  !value.startsWith('0') &&
                  !value.startsWith('+84')) {
                _phoneController.value = TextEditingValue(
                  text: '0$value',
                  selection: TextSelection.collapsed(offset: value.length + 1),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Submit button
          AppButton(
            text: 'Gửi mã OTP',
            onPressed: phoneSignInState.isLoading ? null : _submitForm,
            isLoading: phoneSignInState.isLoading,
            icon: Icons.send,
          ),

          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mã OTP sẽ được gửi qua SMS.',
                    style: TextStyle(color: Colors.blue[700], fontSize: 14),
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
