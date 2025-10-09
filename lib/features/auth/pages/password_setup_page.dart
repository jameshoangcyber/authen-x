import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/utils/validators.dart';
import '../logic/auth_controller.dart';
import '../models/user_model.dart';

class PasswordSetupPage extends ConsumerStatefulWidget {
  const PasswordSetupPage({super.key});

  @override
  ConsumerState<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends ConsumerState<PasswordSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setupPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final password = _passwordController.text.trim();

      // Update password for current user
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updatePassword(password);

      // Update password status in Firestore
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final userRepository = ref.read(userRepositoryProvider);

        // First, check if user profile exists
        final existingProfile = await userRepository.getUserProfile(
          currentUser.uid,
        );

        if (existingProfile == null) {
          // Create user profile if it doesn't exist
          final newProfile = UserModel.fromFirebaseUser(
            currentUser.uid,
            currentUser.phoneNumber ?? '',
            email: currentUser.email,
            displayName: currentUser.displayName,
          );
          await userRepository.createUserProfile(newProfile);
        }

        // Update password status (this will now work with upsert)
        await userRepository.updatePasswordStatus(currentUser.uid, true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật mật khẩu thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );

        // Navigate to profile page
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật mật khẩu: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Cập nhật mật khẩu'),
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
                      'Thiết lập mật khẩu',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Tạo mật khẩu để đăng nhập nhanh hơn lần sau',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Password Form Card
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
                          Icons.security,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thông tin mật khẩu',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Password Field
                    AppTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu mới',
                      hint: 'Nhập mật khẩu mới',
                      validator: Validators.password,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.next,
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

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Xác nhận mật khẩu',
                      hint: 'Nhập lại mật khẩu',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        if (value != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                      obscureText: !_isConfirmPasswordVisible,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isConfirmPasswordVisible
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
                              'Sau khi thiết lập mật khẩu, bạn có thể đăng nhập bằng số điện thoại + mật khẩu hoặc tiếp tục sử dụng SMS OTP.',
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
                text: 'Thiết lập mật khẩu',
                onPressed: _isLoading ? null : _setupPassword,
                isLoading: _isLoading,
                icon: Icons.lock,
              ),

              const SizedBox(height: 16),

              AppButton(
                text: 'Bỏ qua',
                onPressed: () => context.go('/profile'),
                isOutlined: true,
                icon: Icons.skip_next,
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
