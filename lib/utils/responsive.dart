import 'package:flutter/material.dart';

/// Utility class for responsive design using [MediaQuery].
class Responsive {
  static Size size(BuildContext context) => MediaQuery.sizeOf(context);

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Percentage of screen width (0.0 to 1.0 or 0 to 100 via [wp]).
  static double wp(BuildContext context, double percent) =>
      width(context) * (percent / 100);

  /// Percentage of screen height (0 to 100).
  static double hp(BuildContext context, double percent) =>
      height(context) * (percent / 100);

  static bool isMobile(BuildContext context) => width(context) < 600;

  static bool isTablet(BuildContext context) =>
      width(context) >= 600 && width(context) < 1024;

  static bool isDesktop(BuildContext context) => width(context) >= 1024;

  /// Returns a value based on the current device screen size.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Responsive horizontal padding based on screen width.
  static EdgeInsets screenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: value<double>(
        context,
        mobile: 16.0,
        tablet: 32.0,
        desktop: 64.0,
      ),
      vertical: 16.0,
    );
  }
}

