import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/utils/validators.dart';
import '../logic/registration_controller.dart';

class PhoneRegistrationPage extends ConsumerStatefulWidget {
  const PhoneRegistrationPage({super.key});

  @override
  ConsumerState<PhoneRegistrationPage> createState() =>
      _PhoneRegistrationPageState();
}

class _PhoneRegistrationPageState extends ConsumerState<PhoneRegistrationPage> {
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
      ref.read(registrationControllerProvider.notifier).sendOTP(phoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationControllerProvider);

    // Listen for OTP sent state changes
    ref.listen<RegistrationState>(registrationControllerProvider, (
      previous,
      next,
    ) {
      print(
        '🔄 Debug: RegistrationState changed - currentStep: ${next.currentStep}, phoneNumber: ${next.phoneNumber}',
      );
      if (next.currentStep == 2 && next.phoneNumber != null) {
        print('🚀 Debug: Navigating to verification page');
        // Show success message first, then navigate
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã OTP đã được gửi!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate to verification page after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            context.go('/registration-verify');
          });
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Số điện thoại'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/personal-info'),
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
                    Expanded(child: _buildProgressLine(false)),
                    _buildProgressStep(3, 'Xác thực', false),
                  ],
                ),

                const SizedBox(height: 40),

                // Registration icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.person_add,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  'Bước 2: Số điện thoại',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Nhập số điện thoại để nhận mã xác thực OTP',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Phone input form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _phoneController,
                        focusNode: _focusNode,
                        label: 'Số điện thoại',
                        hint: '0901234567',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: Validators.phoneNumber,
                        prefixIcon: Icon(Icons.phone),
                        enabled: !registrationState.isLoading,
                      ),

                      const SizedBox(height: 24),

                      // Register button
                      AppButton(
                        text: 'Gửi mã OTP',
                        onPressed: registrationState.isLoading
                            ? null
                            : _submitForm,
                        isLoading: registrationState.isLoading,
                        icon: Icons.send,
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

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/phone-signin'),
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mã OTP sẽ được gửi qua SMS để xác thực số điện thoại',
                          style: TextStyle(
                            color: Colors.blue[700],
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
                    '$step',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isCompleted ? Colors.grey[800] : Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w500,
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
