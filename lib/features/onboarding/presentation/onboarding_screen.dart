import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/permissions/permission_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.permissionService,
  });

  final PermissionService? permissionService;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PermissionService _permissionService;
  bool _isRequestingPermissions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _permissionService =
        widget.permissionService ?? PermissionHandlerService();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RoadGuard Onboarding'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              'Prepare RoadGuard for real-time driving assistance.',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'RoadGuard needs a small set of device permissions before live detection can begin. Microphone access is not requested.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            const _PermissionReasonCard(
              icon: Icons.videocam_outlined,
              title: 'Camera',
              description:
                  'Used for live road detection so the app can identify potholes, humps, vehicles, and pedestrians ahead.',
            ),
            const SizedBox(height: 16),
            const _PermissionReasonCard(
              icon: Icons.location_on_outlined,
              title: 'Location',
              description:
                  'Used to attach GPS coordinates to hazard detections and support route-aware trip context.',
            ),
            const SizedBox(height: 16),
            const _PermissionReasonCard(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              description:
                  'Used for future safety alerts and important hazard updates when background delivery is needed.',
            ),
            const SizedBox(height: 16),
            const _PermissionReasonCard(
              icon: Icons.screen_rotation_alt_outlined,
              title: 'Motion Sensors',
              description:
                  'Used where supported to improve driving-state sensing with accelerometer and movement signals.',
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isRequestingPermissions
                    ? null
                    : _enableRoadGuardPermissions,
                child: _isRequestingPermissions
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enable RoadGuard Permissions'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
              child: const Text('Review Settings First'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enableRoadGuardPermissions() async {
    setState(() {
      _isRequestingPermissions = true;
      _errorMessage = null;
    });

    final PermissionBatchResult result =
        await _permissionService.requestRequiredPermissions();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRequestingPermissions = false;
    });

    if (result.allRequiredGranted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.driver);
      return;
    }

    setState(() {
      _errorMessage = result.blockingMessages.join('\n');
    });
  }
}

class _PermissionReasonCard extends StatelessWidget {
  const _PermissionReasonCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
