import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/utils/validators.dart';
import '../logic/auth_controller.dart';

class PasswordSignInPage extends ConsumerStatefulWidget {
  const PasswordSignInPage({super.key});

  @override
  ConsumerState<PasswordSignInPage> createState() => _PasswordSignInPageState();
}

class _PasswordSignInPageState extends ConsumerState<PasswordSignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final controller = ref.read(passwordSignInControllerProvider.notifier);
    await controller.signInWithPassword(phoneNumber, password);
  }

  @override
  Widget build(BuildContext context) {
    final passwordSignInState = ref.watch(passwordSignInControllerProvider);

    // Listen for success state
    ref.listen<PasswordSignInState>(passwordSignInControllerProvider, (
      previous,
      next,
    ) {
      if (next.isSuccess && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );

        // Navigate to profile page
        context.go('/profile');

        // Reset state
        ref.read(passwordSignInControllerProvider.notifier).resetState();
      } else if (next.error != null && !next.isLoading) {
        // Extract meaningful error message
        String errorMessage = next.error!;
        if (errorMessage.contains('AuthException:')) {
          errorMessage = errorMessage.replaceFirst('AuthException: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập: $errorMessage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Đăng nhập với mật khẩu'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          onPressed: () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(Icons.lock, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Đăng nhập với mật khẩu',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Nhập số điện thoại và mật khẩu để đăng nhập',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Login Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.login,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thông tin đăng nhập',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Phone Number Field
                    AppTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      hint: 'Nhập số điện thoại',
                      validator: Validators.phoneNumber,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.phone),
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    AppTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      hint: 'Nhập mật khẩu',
                      validator: Validators.password,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
                              'Chỉ áp dụng cho tài khoản đã thiết lập mật khẩu. Nếu chưa có mật khẩu, vui lòng sử dụng SMS OTP.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              AppButton(
                text: 'Đăng nhập',
                onPressed: passwordSignInState.isLoading
                    ? null
                    : _signInWithPassword,
                isLoading: passwordSignInState.isLoading,
                icon: Icons.login,
              ),

              const SizedBox(height: 16),

              AppButton(
                text: 'Quay lại SMS OTP',
                onPressed: () => context.go('/phone-signin'),
                isOutlined: true,
                icon: Icons.sms,
              ),

              const SizedBox(height: 32),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'AuthenX - SMS OTP Authentication',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
