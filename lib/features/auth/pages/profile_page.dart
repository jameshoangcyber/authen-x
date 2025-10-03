import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/app_button.dart';
import '../logic/auth_controller.dart';
import '../logic/registration_controller.dart';
import '../models/user_model.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final signOut = ref.watch(signOutControllerProvider);

    // If user is not authenticated, redirect to splash
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/splash');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return userProfile.when(
      data: (profile) =>
          _buildProfileContent(context, ref, currentUser, profile, signOut),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) {
        // Handle PERMISSION_DENIED error
        if (error.toString().contains('permission-denied')) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Cần cấu hình Firestore',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng cấu hình Security Rules trong Firebase Console',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/splash'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Show profile with basic info only
                      _buildProfileContent(
                        context,
                        ref,
                        currentUser,
                        null,
                        signOut,
                      );
                    },
                    child: const Text('Xem thông tin cơ bản'),
                  ),
                ],
              ),
            ),
          );
        }

        // Other errors
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi khi tải thông tin: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/splash'),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    currentUser,
    UserModel? profile,
    signOut,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await signOut();
                if (context.mounted) {
                  context.go('/splash');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi đăng xuất: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Profile avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              // Welcome text
              Text(
                'Chào mừng!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Bạn đã đăng nhập thành công',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // User info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin tài khoản',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // User ID
                      _buildInfoRow(
                        context,
                        icon: Icons.fingerprint,
                        label: 'User ID',
                        value: currentUser.uid,
                      ),

                      const SizedBox(height: 16),

                      // Phone number
                      _buildInfoRow(
                        context,
                        icon: Icons.phone,
                        label: 'Số điện thoại',
                        value:
                            profile?.phoneNumber ??
                            currentUser.phoneNumber ??
                            'Không có',
                      ),

                      const SizedBox(height: 16),

                      // Full name
                      if (profile?.fullName != null) ...[
                        _buildInfoRow(
                          context,
                          icon: Icons.person,
                          label: 'Họ tên',
                          value: profile!.fullName,
                        ),
                        const SizedBox(height: 16),
                      ] else if (profile == null) ...[
                        _buildInfoRow(
                          context,
                          icon: Icons.person,
                          label: 'Họ tên',
                          value: 'Chưa cập nhật (Cần cấu hình Firestore)',
                          valueColor: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email (if available)
                      _buildInfoRow(
                        context,
                        icon: Icons.email,
                        label: 'Email',
                        value:
                            profile?.email ?? currentUser.email ?? 'Không có',
                      ),

                      const SizedBox(height: 16),

                      // Email verified
                      _buildInfoRow(
                        context,
                        icon:
                            (profile?.isEmailVerified ??
                                currentUser.emailVerified)
                            ? Icons.verified
                            : Icons.warning,
                        label: 'Email đã xác thực',
                        value:
                            (profile?.isEmailVerified ??
                                currentUser.emailVerified)
                            ? 'Có'
                            : 'Không',
                        valueColor:
                            (profile?.isEmailVerified ??
                                currentUser.emailVerified)
                            ? Colors.green
                            : Colors.orange,
                      ),

                      // Address
                      if (profile?.address != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          icon: Icons.location_on,
                          label: 'Địa chỉ',
                          value: profile!.address!,
                        ),
                      ],

                      // Date of birth
                      if (profile?.dateOfBirth != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          icon: Icons.cake,
                          label: 'Ngày sinh',
                          value: _formatDate(profile!.dateOfBirth),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Creation time
                      _buildInfoRow(
                        context,
                        icon: Icons.access_time,
                        label: 'Ngày tạo tài khoản',
                        value: _formatDate(currentUser.metadata.creationTime),
                      ),

                      const SizedBox(height: 16),

                      // Last sign in
                      _buildInfoRow(
                        context,
                        icon: Icons.login,
                        label: 'Lần đăng nhập cuối',
                        value: _formatDate(currentUser.metadata.lastSignInTime),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Sign out button
              AppButton(
                text: 'Đăng xuất',
                onPressed: () async {
                  try {
                    await signOut();
                    if (context.mounted) {
                      context.go('/splash');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi khi đăng xuất: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                icon: Icons.logout,
                isOutlined: true,
              ),

              const SizedBox(height: 32),

              // Footer
              Text(
                'AuthenX - SMS OTP Authentication',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không có';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
