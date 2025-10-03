import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/utils/validators.dart';
import '../logic/auth_controller.dart';

class EmailRegistrationPage extends ConsumerStatefulWidget {
  const EmailRegistrationPage({super.key});

  @override
  ConsumerState<EmailRegistrationPage> createState() =>
      _EmailRegistrationPageState();
}

class _EmailRegistrationPageState extends ConsumerState<EmailRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      ref
          .read(emailRegistrationControllerProvider.notifier)
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailRegistrationState = ref.watch(
      emailRegistrationControllerProvider,
    );

    // Listen for registration success
    ref.listen<EmailRegistrationState>(emailRegistrationControllerProvider, (
      previous,
      next,
    ) {
      print(
        '🔄 Debug: EmailRegistrationState changed - isRegistered: ${next.isRegistered}, isLoading: ${next.isLoading}, error: ${next.error}',
      );

      if (next.isRegistered && !next.isLoading) {
        print('🚀 Debug: Email registration successful, navigating to sign in');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Reset state
          ref.read(emailRegistrationControllerProvider.notifier).resetState();
          // Navigate to sign in page
          context.go('/email-signin');
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/auth-method-register'),
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

                // Email icon
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
                    Icons.person_add,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Tạo tài khoản mới',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Nhập thông tin để tạo tài khoản',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Registration form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // First name field
                      AppTextField(
                        controller: _firstNameController,
                        label: 'Họ *',
                        hint: 'Nguyễn',
                        validator: Validators.required,
                        prefixIcon: Icon(Icons.person),
                        enabled: !emailRegistrationState.isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Last name field
                      AppTextField(
                        controller: _lastNameController,
                        label: 'Tên *',
                        hint: 'Văn A',
                        validator: Validators.required,
                        prefixIcon: Icon(Icons.person_outline),
                        enabled: !emailRegistrationState.isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Email field
                      AppTextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: 'Email *',
                        hint: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        prefixIcon: Icon(Icons.email),
                        enabled: !emailRegistrationState.isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Password field
                      AppTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        label: 'Mật khẩu *',
                        hint: 'Tối thiểu 6 ký tự',
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                        enabled: !emailRegistrationState.isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Confirm password field
                      AppTextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        label: 'Xác nhận mật khẩu *',
                        hint: 'Nhập lại mật khẩu',
                        obscureText: _obscureConfirmPassword,
                        validator: _validateConfirmPassword,
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                        enabled: !emailRegistrationState.isLoading,
                      ),

                      const SizedBox(height: 32),

                      // Register button
                      AppButton(
                        text: 'Tạo tài khoản',
                        onPressed: emailRegistrationState.isLoading
                            ? null
                            : _submitForm,
                        isLoading: emailRegistrationState.isLoading,
                        icon: Icons.person_add,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Error message
                if (emailRegistrationState.error != null)
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
                            emailRegistrationState.error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(
                                  emailRegistrationControllerProvider.notifier,
                                )
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
                      onPressed: () => context.go('/email-signin'),
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Other registration methods
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Hoặc',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 24),

                // SMS OTP button
                OutlinedButton.icon(
                  onPressed: () => context.go('/phone-registration'),
                  icon: const Icon(Icons.sms),
                  label: const Text('Đăng ký bằng SMS'),
                ),

                const SizedBox(height: 24),

                // Footer
                Text(
                  'AuthenX - Multi-Authentication',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
