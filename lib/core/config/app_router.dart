import 'package:flutter/material.dart';

import '../../features/camera_detection/presentation/camera_detection_screen.dart';
import '../../features/driver_mode/presentation/driver_mode_screen.dart';
import '../../features/hazard_map/presentation/hazard_map_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/trip_summary/presentation/trip_summary_screen.dart';
import '../constants/app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return _materialRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
        );
      case AppRoutes.driver:
        return _materialRoute(
          settings: settings,
          builder: (_) => const DriverModeScreen(),
        );
      case AppRoutes.camera:
        return _materialRoute(
          settings: settings,
          builder: (_) => const CameraDetectionScreen(),
        );
      case AppRoutes.map:
        return _materialRoute(
          settings: settings,
          builder: (_) => const HazardMapScreen(),
        );
      case AppRoutes.summary:
        return _materialRoute(
          settings: settings,
          builder: (_) => const TripSummaryScreen(),
        );
      case AppRoutes.settings:
        return _materialRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );
      default:
        return _materialRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
        );
    }
  }

  static MaterialPageRoute<dynamic> _materialRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: builder,
    );
  }
}
