import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:nexi/core/constants/app_colors.dart';
import 'package:nexi/core/utils/helper.dart';
import 'package:nexi/features/auth/data/models/user_model.dart';
import 'package:nexi/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_messaging_service.dart';
import '../../../../core/services/zego_service.dart';
import '../../../../core/utils/font_style.dart';
import 'widgets/login_form.dart';
import 'widgets/signup_form.dart';
import 'widgets/tab_icon.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final pageController = PageController();
  final scrollController = ScrollController();
  int selectedIndex = 0;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = scrollController.offset;
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.35;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LoginError) {
            Helper.showSnackBarMessage(context, state.errmsg, true);
          } else if (state is RegisterError) {
            Helper.showSnackBarMessage(context, state.errMsg, true);
          } else if (state is LoginLoaded) {
            _initZego(state.user);
            GoRouter.of(context).goNamed('home');
            FirebaseMessagingService.initForUser(state.user.id!);
          } else if (state is RegisterLoaded) {
            _initZego(state.user);
            GoRouter.of(context).goNamed('home');
            FirebaseMessagingService.initForUser(state.user.id!);
          } else if (state is AuthResetPassword) {
            Helper.showSnackBarMessage(context, 'Check your email', false);
          }
        },
        builder: (BuildContext context, AuthState state) {
          return ModalProgressHUD(
            inAsyncCall: state is LoginLoading || state is RegisterLoading,
            opacity: 0.7,
            progressIndicator: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                // Header Section with Parallax Effect
                SliverAppBar(
                  expandedHeight: headerHeight,
                  collapsedHeight: 50.h,
                  floating: true,
                  snap: true,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: _scrollOffset > 0 ? 2 : 0,
                  shadowColor: Colors.black12,
                  surfaceTintColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _buildHeaderSection(),
                    title: _scrollOffset > headerHeight - 100
                        ? Text(
                            selectedIndex == 0
                                ? 'Welcome Back'
                                : 'Create Account',
                            style: AppFontStyle.body16.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                    centerTitle: true,
                  ),
                ),

                // Main Content Section
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.r),
                        topRight: Radius.circular(30.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 32.h,
                      ),
                      child: Column(
                        children: [
                          // Auth Tabs
                          _buildAuthTabs(),

                          // Forms Section
                          SizedBox(
                            height:
                                _calculateFormHeight(), // You need to implement this
                            child: PageView(
                              physics: const NeverScrollableScrollPhysics(),
                              controller: pageController,
                              children: const [LoginForm(), RegisterForm()],
                            ),
                          ),

                          // Social Login Section
                          _buildSocialLoginSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Logo based on scroll
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _scrollOffset > 50 ? 80.w : 120.w,
            height: _scrollOffset > 50 ? 80.w : 120.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            padding: EdgeInsets.all(_scrollOffset > 50 ? 16.w : 24.w),
            child: Image.asset(AppConstants.appLogo, fit: BoxFit.contain),
          ),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _scrollOffset > 100 ? 0 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _scrollOffset > 100 ? 0 : null,
              child: Column(
                children: [
                  SizedBox(height: 24.h),

                  // Welcome Text
                  Text(
                    selectedIndex == 0 ? 'Welcome Back!' : 'Create Account',
                    style: AppFontStyle.title24.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Subtitle
                  Text(
                    selectedIndex == 0
                        ? 'Sign in to continue your journey'
                        : 'Join us and start your journey',
                    style: AppFontStyle.body16.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthTabs() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          TabIcon(
            title: 'Login',
            color: selectedIndex == 0 ? AppColors.primary : Colors.transparent,
            textColor: selectedIndex == 0 ? Colors.white : Colors.grey.shade600,
            onTap: () => _animateToPage(0),
            boxShadow: selectedIndex == 0
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          SizedBox(width: 8.w),
          TabIcon(
            title: 'Register',
            color: selectedIndex == 1 ? AppColors.primary : Colors.transparent,
            textColor: selectedIndex == 1 ? Colors.white : Colors.grey.shade600,
            onTap: () => _animateToPage(1),
            boxShadow: selectedIndex == 1
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'Or continue with',
                style: AppFontStyle.body14.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),

        SizedBox(height: 24.h),

        // Social buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: FontAwesomeIcons.google,
              color: Colors.red,
              onTap: () =>
                  context.read<AuthBloc>().add(SignInWithGoogleEvent()),
            ),
            SizedBox(width: 20.w),
            _buildSocialButton(
              icon: FontAwesomeIcons.facebook,
              color: Colors.blue,
              onTap: () =>
                  context.read<AuthBloc>().add(SignInWithFacebookEvent()),
            ),
          ],
        ),

        SizedBox(height: 20.h),

        // Footer text
        Text(
          'By continuing, you agree to our Terms of Service\nand Privacy Policy',
          style: AppFontStyle.caption12.copyWith(
            color: Colors.grey.shade500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30.w),
      ),
    );
  }

  void _animateToPage(int index) {
    setState(() {
      selectedIndex = index;
    });
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  double _calculateFormHeight() {
    if (selectedIndex == 0) {
      return 400;
    } else {
      return 500;
    }
  }

  void _initZego(UserModel user) {
    ZegoService.updateUser(user.id!, user.name!);
  }
}
