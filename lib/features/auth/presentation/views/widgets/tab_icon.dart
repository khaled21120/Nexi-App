import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nexi/core/utils/font_style.dart';

class TabIcon extends StatelessWidget {
  const TabIcon({
    super.key,
    required this.title,
    required this.color,
    required this.textColor,
    required this.onTap,
    required this.boxShadow,
  });
  final String title;
  final Color color, textColor;
  final VoidCallback onTap;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: boxShadow,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppFontStyle.body16.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
