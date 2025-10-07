import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nexi/core/utils/font_style.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/helper.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../bloc/auth_bloc.dart';
import 'password_textfield.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final resetController = TextEditingController();
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  bool isPasswordVisible = true;

  void showResetPasswordAlert() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: CustomTextfield(label: 'Email', controller: resetController),
          actions: [
            TextButton(
              child: const Text('Reset'),
              onPressed: () {
                if (resetController.text.isNotEmpty) {
                  context.read<AuthBloc>().add(
                    ResetPasswordEvent(email: resetController.text.trim()),
                  );
                  Navigator.of(ctx).pop();
                } else {
                  Helper.showSnackBarMessage(
                    context,
                    'Please enter your email',
                    true,
                  );
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    resetController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 15.h,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextfield(
            label: 'Email',
            controller: emailController,
            icon: const Icon(Icons.email),
            validator: (p0) {
              if (p0 == null || p0.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(p0)) {
                return 'Please enter a valid email';
              }
              return null; // valid
            },
          ),
          PasswordTextfield(
            label: 'Password',
            controller: passwordController,
            isPasswordVisible: isPasswordVisible,
            validator: (p0) {
              if (p0 == null || p0.isEmpty) return 'Please enter your password';
              if (p0.length < 8) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onTap: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                showResetPasswordAlert();
              },
              child: Text(
                'Forgot Password?',

                style: AppFontStyle.body14.copyWith(
                  color: AppColors.primary.withValues(alpha: .7),
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
          CustomButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                context.read<AuthBloc>().add(
                  LoginEvent(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  ),
                );
                setState(() {
                  autovalidateMode = AutovalidateMode.always;
                });
              }
            },
            label: 'Login',
          ),
        ],
      ),
    );
  }
}
