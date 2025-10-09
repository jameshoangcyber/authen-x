import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/utils/validators.dart';
import '../logic/auth_controller.dart';
import '../models/user_model.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final UserModel? currentProfile;

  const EditProfilePage({super.key, this.currentProfile});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.currentProfile != null) {
      final profile = widget.currentProfile!;
      _firstNameController.text = profile.firstName ?? '';
      _lastNameController.text = profile.lastName ?? '';
      _emailController.text = profile.email ?? '';
      _addressController.text = profile.address ?? '';
      _selectedDateOfBirth = profile.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      print('Error formatting date: $e');
      // Fallback to manual formatting
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Future<void> _selectDateOfBirth() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate:
            _selectedDateOfBirth ??
            DateTime.now().subtract(const Duration(days: 365 * 18)),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && picked != _selectedDateOfBirth) {
        setState(() {
          _selectedDateOfBirth = picked;
        });
      }
    } catch (e) {
      print('Error selecting date: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ngày: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Create updated user model
      final updatedProfile = UserModel(
        uid: currentUser.uid,
        phoneNumber:
            widget.currentProfile?.phoneNumber ?? currentUser.phoneNumber ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        isEmailVerified: widget.currentProfile?.isEmailVerified ?? false,
        hasPassword: widget.currentProfile?.hasPassword ?? false,
        createdAt: widget.currentProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update profile in Firestore
      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật: $e'),
            backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Header
                Text(
                  'Cập nhật thông tin cá nhân',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Vui lòng điền thông tin bạn muốn cập nhật',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // First Name
                AppTextField(
                  controller: _firstNameController,
                  label: 'Họ',
                  hint: 'Nhập họ của bạn',
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // Last Name
                AppTextField(
                  controller: _lastNameController,
                  label: 'Tên',
                  hint: 'Nhập tên của bạn',
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // Email
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Nhập email của bạn (tùy chọn)',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return Validators.email(value);
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // Address
                AppTextField(
                  controller: _addressController,
                  label: 'Địa chỉ',
                  hint: 'Nhập địa chỉ của bạn (tùy chọn)',
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 16),

                // Date of Birth
                InkWell(
                  onTap: _selectDateOfBirth,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cake, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ngày sinh',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedDateOfBirth != null
                                    ? _formatDate(_selectedDateOfBirth!)
                                    : 'Chọn ngày sinh (tùy chọn)',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: _selectedDateOfBirth != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Save button
                AppButton(
                  text: 'Lưu thông tin',
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                  icon: Icons.save,
                ),

                const SizedBox(height: 16),

                // Cancel button
                AppButton(
                  text: 'Hủy',
                  onPressed: () => context.pop(),
                  isOutlined: true,
                  icon: Icons.close,
                ),

                const SizedBox(height: 32),

                // Info text
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
                          'Thông tin sẽ được lưu vào Firestore. Đảm bảo bạn đã cấu hình Security Rules.',
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
        ),
      ),
    );
  }
}
