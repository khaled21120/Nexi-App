import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../bloc/auth_bloc.dart';
import 'password_textfield.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isPasswordVisible = true;
  bool isConfirmPasswordVisible = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
            label: 'Full Name',
            controller: nameController,
            icon: const Icon(Icons.person),
            validator: (p0) {
              if (p0 == null || p0.isEmpty) return 'Please enter your name';
              if (p0.length < 3) return 'Name must be at least 3 characters';
              return null;
            },
          ),
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
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            onTap: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
          PasswordTextfield(
            label: 'Confirm Password',
            controller: confirmPasswordController,
            isPasswordVisible: isConfirmPasswordVisible,
            validator: (p0) {
              if (p0 == null || p0.isEmpty) {
                return 'Please confirm your password';
              }
              if (p0 != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onTap: () {
              setState(() {
                isConfirmPasswordVisible = !isConfirmPasswordVisible;
              });
            },
          ),
          CustomButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                context.read<AuthBloc>().add(
                  RegisterEvent(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  ),
                );
              } else {
                setState(() {
                  autovalidateMode = AutovalidateMode.always;
                });
              }
            },
            label: 'Register',
          ),
        ],
      ),
    );
  }
}
