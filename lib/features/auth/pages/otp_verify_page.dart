import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/otp_input_form.dart';
import '../logic/auth_controller.dart';

class OtpVerifyPage extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerifyPage({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for authentication success in build method
    ref.listen(currentUserProvider, (previous, next) {
      print(
        '🔄 Debug: currentUserProvider changed - previous: ${previous?.uid}, next: ${next?.uid}',
      );
      print(
        '🔄 Debug: previous is null: ${previous == null}, next is not null: ${next != null}',
      );

      if (next != null) {
        print(
          '✅ Debug: User authenticated successfully, navigating to profile',
        );
        // User successfully authenticated, navigate to profile
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('🚀 Debug: Executing navigation to profile');
          context.go('/profile');
        });
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực OTP'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // OTP icon
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
                    Icons.sms,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 40),

                // OTP input form
                OtpInputForm(phoneNumber: widget.phoneNumber),

                const SizedBox(height: 40),

                // Footer
                Text(
                  'Mã OTP sẽ được gửi qua SMS',
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
