import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/utils/validators.dart';
import '../logic/auth_controller.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Check if user is phone auth user
      if (currentUser.phoneNumber != null) {
        // For phone auth users, we can't re-authenticate with password
        // So we'll just update the password directly
        await authRepository.updatePassword(newPassword);

        // Update password status in Firestore
        final userRepository = ref.read(userRepositoryProvider);
        await userRepository.updatePasswordStatus(currentUser.uid, true);
      } else {
        // For email users, use normal flow
        if (currentPassword.isEmpty) {
          // First-time password setup
          await authRepository.updatePassword(newPassword);

          // Update password status in Firestore
          final userRepository = ref.read(userRepositoryProvider);
          await userRepository.updatePasswordStatus(currentUser.uid, true);
        } else {
          // Normal password change flow
          await authRepository.reauthenticateUser(currentPassword);
          await authRepository.updatePassword(newPassword);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết lập/Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );

        // Navigate back to profile
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('AuthException:')) {
          errorMessage = errorMessage.replaceFirst('AuthException: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thiết lập/đổi mật khẩu: $errorMessage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            duration: const Duration(seconds: 4),
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
    final currentUser = ref.watch(currentUserProvider);
    final isPhoneUser = currentUser?.phoneNumber != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thiết lập/Đổi mật khẩu'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          onPressed: () => context.pop(),
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
                      child: Icon(
                        Icons.lock_reset,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      isPhoneUser
                          ? 'Thiết lập mật khẩu'
                          : 'Thiết lập/Đổi mật khẩu',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      isPhoneUser
                          ? 'Thiết lập mật khẩu cho tài khoản SMS OTP'
                          : 'Nhập mật khẩu hiện tại (nếu có) và mật khẩu mới',
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

                    // Current Password Field (only for email users)
                    if (!isPhoneUser) ...[
                      AppTextField(
                        controller: _currentPasswordController,
                        label: 'Mật khẩu hiện tại',
                        hint: 'Nhập mật khẩu hiện tại (để trống nếu chưa có)',
                        validator: (value) {
                          // Allow empty for first-time password setup
                          return null;
                        },
                        obscureText: !_isCurrentPasswordVisible,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isCurrentPasswordVisible =
                                  !_isCurrentPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isCurrentPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],

                    // New Password Field
                    AppTextField(
                      controller: _newPasswordController,
                      label: isPhoneUser ? 'Mật khẩu mới' : 'Mật khẩu mới',
                      hint: 'Nhập mật khẩu mới',
                      validator: Validators.password,
                      obscureText: !_isNewPasswordVisible,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isNewPasswordVisible
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
                      label: 'Xác nhận mật khẩu mới',
                      hint: 'Nhập lại mật khẩu mới',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu mới';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                      obscureText: !_isConfirmPasswordVisible,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_outline),
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
                              isPhoneUser
                                  ? 'Thiết lập mật khẩu để có thể đăng nhập bằng mật khẩu sau này.'
                                  : 'Mật khẩu mới phải có ít nhất 6 ký tự và chứa cả chữ cái và số.',
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
                text: isPhoneUser
                    ? 'Thiết lập mật khẩu'
                    : 'Thiết lập/Đổi mật khẩu',
                onPressed: _isLoading ? null : _changePassword,
                isLoading: _isLoading,
                icon: Icons.lock_reset,
              ),

              const SizedBox(height: 16),

              AppButton(
                text: 'Hủy',
                onPressed: () => context.pop(),
                isOutlined: true,
                icon: Icons.close,
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
