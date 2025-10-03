import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/utils/validators.dart';
import '../logic/registration_controller.dart';

class PersonalInfoPage extends ConsumerStatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  ConsumerState<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends ConsumerState<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Reset registration state when entering personal info page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrationControllerProvider.notifier).resetState();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // 18 years ago
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(registrationControllerProvider.notifier)
          .updatePersonalInfoFirst(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
            dateOfBirth: _selectedDate,
            address: _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationControllerProvider);

    // Listen for personal info updated
    ref.listen<RegistrationState>(registrationControllerProvider, (
      previous,
      next,
    ) {
      print(
        '🔄 Debug: RegistrationState in personal info page - currentStep: ${next.currentStep}, isLoading: ${next.isLoading}, previous: ${previous?.currentStep}',
      );
      // Only navigate if we just completed personal info (currentStep changed from 0 to 1)
      if (next.currentStep == 1 &&
          previous?.currentStep == 0 &&
          !next.isLoading &&
          next.firstName != null &&
          next.lastName != null) {
        print('🚀 Debug: Personal info completed, navigating to phone step');
        // Show success message first, then navigate
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thông tin cá nhân đã được lưu!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate to phone step after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            context.go('/phone-registration');
          });
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
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

                // Progress indicator
                Row(
                  children: [
                    _buildProgressStep(1, 'Thông tin', true),
                    Expanded(child: _buildProgressLine(false)),
                    _buildProgressStep(2, 'Số điện thoại', false),
                    Expanded(child: _buildProgressLine(false)),
                    _buildProgressStep(3, 'Xác thực', false),
                  ],
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  'Bước 1: Thông tin cá nhân',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Vui lòng cung cấp thông tin cá nhân của bạn để bắt đầu đăng ký',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Personal info form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // First name
                      AppTextField(
                        controller: _firstNameController,
                        label: 'Họ *',
                        hint: 'Nguyễn',
                        validator: Validators.required,
                        prefixIcon: Icon(Icons.person),
                        enabled: !registrationState.isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Last name
                      AppTextField(
                        controller: _lastNameController,
                        label: 'Tên *',
                        hint: 'Văn A',
                        validator: Validators.required,
                        prefixIcon: Icon(Icons.person_outline),
                        enabled: !registrationState.isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Email
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            return Validators.email(value);
                          }
                          return null;
                        },
                        prefixIcon: Icon(Icons.email),
                        enabled: !registrationState.isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Date of birth
                      AppTextField(
                        controller: _dateOfBirthController,
                        label: 'Ngày sinh',
                        hint: 'DD/MM/YYYY',
                        onTap: _selectDate,
                        prefixIcon: Icon(Icons.calendar_today),
                        enabled: !registrationState.isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Address
                      AppTextField(
                        controller: _addressController,
                        label: 'Địa chỉ',
                        hint:
                            'Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành phố',
                        prefixIcon: Icon(Icons.location_on),
                        enabled: !registrationState.isLoading,
                      ),

                      const SizedBox(height: 32),

                      // Continue button
                      AppButton(
                        text: 'Tiếp tục',
                        onPressed: registrationState.isLoading
                            ? null
                            : _submitForm,
                        isLoading: registrationState.isLoading,
                        icon: Icons.arrow_forward,
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

                const SizedBox(height: 24),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Thông tin có dấu * là bắt buộc. Email sẽ được dùng để xác thực tài khoản.',
                          style: TextStyle(
                            color: Colors.orange[700],
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
                    step.toString(),
                    style: TextStyle(
                      color: isCompleted ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isCompleted
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
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
