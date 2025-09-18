import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final String? iconPath;
  final String? rightIconPath;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    this.iconPath,
    this.rightIconPath,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null) ...[
            Image.asset(iconPath!, height: 18.48, width: 48),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: textColor,
              height: 1.0,
              letterSpacing: 1,
            ),
          ),
          if (rightIconPath != null) ...[
            const SizedBox(width: 8),
            Image.asset(rightIconPath!, height: 18.48),
          ],
        ],
      ),
    );
  }
}