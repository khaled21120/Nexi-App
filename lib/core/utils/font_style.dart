import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

abstract class AppFontStyle {
  static final _baseFont = GoogleFonts.poppins;

  // Headline styles
  static TextStyle title32 = _baseFont(
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    height: 1.3,
    letterSpacing: -0.5,
  );

  static TextStyle title28 = _baseFont(
    fontSize: 28.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    height: 1.3,
  );

  static TextStyle title24 = _baseFont(
    fontSize: 24.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  // Subtitle styles
  static TextStyle subtitle20 = _baseFont(
    fontSize: 20.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.black.withValues(alpha: 0.8),
  );

  static TextStyle subtitle18 = _baseFont(
    fontSize: 18.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black.withValues(alpha: 0.8),
  );

  // Body text styles
  static TextStyle body16 = _baseFont(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
    height: 1.5,
  );

  static TextStyle body14 = _baseFont(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
    height: 1.5,
  );

  // Caption & Small text
  static TextStyle caption12 = _baseFont(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.gray,
  );

  static TextStyle overline = _baseFont(
    fontSize: 10.sp,
    fontWeight: FontWeight.w300,
    color: AppColors.gray,
    letterSpacing: 0.5,
  );

  // Buttons
  static TextStyle button = _baseFont(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.8,
  );
}
