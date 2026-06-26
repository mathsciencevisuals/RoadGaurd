import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../shared/presentation/feature_placeholder_screen.dart';

class CameraDetectionScreen extends StatelessWidget {
  const CameraDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScreen(
      title: 'Camera Detection',
      description:
          'This module will host the camera preview, frame pipeline, and hazard overlays backed by TensorFlow Lite later.',
      primaryActionLabel: 'View Hazard Map',
      primaryActionRoute: AppRoutes.map,
    );
  }
}
