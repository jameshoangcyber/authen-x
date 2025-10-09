import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/app_button.dart';
import '../logic/auth_controller.dart';
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
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, ref, error),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải thông tin...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    // Handle PERMISSION_DENIED error
    if (error.toString().contains('permission-denied')) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.security,
                    size: 40,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cần cấu hình Firestore',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vui lòng cấu hình Security Rules trong Firebase Console để truy cập thông tin người dùng.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Thử lại',
                  onPressed: () => context.go('/splash'),
                  icon: Icons.refresh,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Xem thông tin cơ bản',
                  onPressed: () {
                    // Show profile with basic info only
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => _buildProfileContent(
                          context,
                          ref,
                          ref.read(currentUserProvider)!,
                          null,
                          ref.read(signOutControllerProvider),
                        ),
                      ),
                    );
                  },
                  isOutlined: true,
                  icon: Icons.info_outline,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Other errors
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Lỗi khi tải thông tin',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Thử lại',
                onPressed: () => context.go('/splash'),
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Profile Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Welcome Text
                  Text(
                    'Chào mừng trở lại!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Bạn đã đăng nhập thành công',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Profile Information Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                children: [
                  // Card Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Thông tin tài khoản',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.push('/edit-profile', extra: profile),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Chỉnh sửa'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          context,
                          icon: Icons.fingerprint,
                          title: 'User ID',
                          value: currentUser.uid,
                          color: Colors.blue,
                        ),

                        const SizedBox(height: 12),

                        _buildInfoCard(
                          context,
                          icon: Icons.phone,
                          title: 'Số điện thoại',
                          value:
                              profile?.phoneNumber ??
                              currentUser.phoneNumber ??
                              'Không có',
                          color: Colors.green,
                        ),

                        if (profile?.fullName != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            icon: Icons.person,
                            title: 'Họ tên',
                            value: profile!.fullName,
                            color: Colors.purple,
                          ),
                        ] else if (profile == null) ...[
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            icon: Icons.person,
                            title: 'Họ tên',
                            value: 'Chưa cập nhật (Cần cấu hình Firestore)',
                            color: Colors.orange,
                            isWarning: true,
                          ),
                        ],

                        const SizedBox(height: 12),

                        _buildInfoCard(
                          context,
                          icon: Icons.email,
                          title: 'Email',
                          value:
                              profile?.email ?? currentUser.email ?? 'Không có',
                          color: Colors.blue,
                        ),

                        const SizedBox(height: 12),

                        _buildInfoCard(
                          context,
                          icon:
                              profile?.isEmailVerified ??
                                  currentUser.emailVerified
                              ? Icons.verified
                              : Icons.warning,
                          title: 'Email đã xác thực',
                          value:
                              profile?.isEmailVerified ??
                                  currentUser.emailVerified
                              ? 'Có'
                              : 'Không',
                          color:
                              profile?.isEmailVerified ??
                                  currentUser.emailVerified
                              ? Colors.green
                              : Colors.orange,
                          isWarning:
                              !(profile?.isEmailVerified ??
                                  currentUser.emailVerified),
                        ),

                        const SizedBox(height: 12),

                        _buildInfoCard(
                          context,
                          icon: profile?.hasPassword ?? false
                              ? Icons.lock
                              : Icons.lock_open,
                          title: 'Mật khẩu đã thiết lập',
                          value: profile?.hasPassword ?? false
                              ? 'Có'
                              : 'Chưa thiết lập',
                          color: profile?.hasPassword ?? false
                              ? Colors.green
                              : Colors.orange,
                          isWarning: !(profile?.hasPassword ?? false),
                        ),

                        if (profile?.address != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            icon: Icons.location_on,
                            title: 'Địa chỉ',
                            value: profile!.address!,
                            color: Colors.red,
                          ),
                        ],

                        if (profile?.dateOfBirth != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            icon: Icons.cake,
                            title: 'Ngày sinh',
                            value: _formatDate(profile!.dateOfBirth),
                            color: Colors.pink,
                          ),
                        ],

                        const SizedBox(height: 12),

                        _buildInfoCard(
                          context,
                          icon: Icons.access_time,
                          title: 'Ngày tạo tài khoản',
                          value: _formatDate(currentUser.metadata.creationTime),
                          color: Colors.grey,
                        ),

                        const SizedBox(height: 12),

                        _buildInfoCard(
                          context,
                          icon: Icons.login,
                          title: 'Lần đăng nhập cuối',
                          value: _formatDate(
                            currentUser.metadata.lastSignInTime,
                          ),
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  AppButton(
                    text: 'Chỉnh sửa thông tin',
                    onPressed: () =>
                        context.push('/edit-profile', extra: profile),
                    icon: Icons.edit,
                    isOutlined: false,
                  ),

                  const SizedBox(height: 12),

                  // Show change password button for authenticated users
                  AppButton(
                    text: 'Thiết lập/Đổi mật khẩu',
                    onPressed: () => context.push('/change-password'),
                    icon: Icons.lock_reset,
                    isOutlined: false,
                  ),

                  const SizedBox(height: 12),

                  AppButton(
                    text: 'Đăng xuất',
                    onPressed: () => _handleSignOut(context, signOut),
                    icon: Icons.logout,
                    isOutlined: true,
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? Colors.orange.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? Colors.orange.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isWarning ? Colors.orange[700] : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, signOut) async {
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không có';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
