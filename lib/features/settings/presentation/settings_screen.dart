import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../application/settings_controller.dart';
import '../domain/roadguard_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _initialization = _controller.initialize();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Settings'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.onboarding),
                    child: const Text('Onboarding'),
                  ),
                ],
              ),
              body: SafeArea(
                child: _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: <Widget>[
                          _SectionCard(
                            title: 'Alerts',
                            subtitle:
                                'Control how RoadGuard warns the driver about nearby road hazards.',
                            child: Column(
                              children: <Widget>[
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Enable voice alerts'),
                                  subtitle: const Text(
                                    'Speak hazard warnings while driving.',
                                  ),
                                  value:
                                      _controller.settings.enableVoiceAlerts,
                                  onChanged:
                                      _controller.setVoiceAlertsEnabled,
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Enable vibration alerts'),
                                  subtitle: const Text(
                                    'Trigger haptic feedback for high-priority detections.',
                                  ),
                                  value: _controller
                                      .settings.enableVibrationAlerts,
                                  onChanged:
                                      _controller.setVibrationAlertsEnabled,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<AlertSensitivity>(
                                  value:
                                      _controller.settings.alertSensitivity,
                                  decoration: const InputDecoration(
                                    labelText: 'Alert sensitivity',
                                  ),
                                  items: AlertSensitivity.values
                                      .map(
                                        (
                                          AlertSensitivity sensitivity,
                                        ) =>
                                            DropdownMenuItem<AlertSensitivity>(
                                          value: sensitivity,
                                          child: Text(
                                            _sensitivityLabel(sensitivity),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (
                                    AlertSensitivity? value,
                                  ) {
                                    if (value == null) {
                                      return;
                                    }

                                    _controller.setAlertSensitivity(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Detection',
                            subtitle:
                                'Tune the camera pipeline and development diagnostics.',
                            child: Column(
                              children: <Widget>[
                                DropdownButtonFormField<int>(
                                  value: _controller
                                      .settings.detectionProcessingFps,
                                  decoration: const InputDecoration(
                                    labelText: 'Detection processing FPS',
                                  ),
                                  items: RoadGuardSettings.supportedFpsValues
                                      .map(
                                        (int fps) =>
                                            DropdownMenuItem<int>(
                                          value: fps,
                                          child: Text('$fps FPS'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (int? value) {
                                    if (value == null) {
                                      return;
                                    }

                                    _controller
                                        .setDetectionProcessingFps(value);
                                  },
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title:
                                      const Text('Enable debug bounding boxes'),
                                  subtitle: const Text(
                                    'Render detection boxes for QA and tuning.',
                                  ),
                                  value: _controller
                                      .settings.enableDebugBoundingBoxes,
                                  onChanged: _controller
                                      .setDebugBoundingBoxesEnabled,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Data & Sync',
                            subtitle:
                                'Choose how local trip and hazard data is synchronized and shared.',
                            child: Column(
                              children: <Widget>[
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Enable cloud sync'),
                                  subtitle: const Text(
                                    'Upload pending hazards and trip events when connectivity returns.',
                                  ),
                                  value:
                                      _controller.settings.enableCloudSync,
                                  onChanged:
                                      _controller.setCloudSyncEnabled,
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Enable data sharing for road improvement',
                                  ),
                                  subtitle: const Text(
                                    'Share anonymized road insights to improve hazard coverage.',
                                  ),
                                  value:
                                      _controller.settings.enableDataSharing,
                                  onChanged:
                                      _controller.setDataSharingEnabled,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _confirmClearLocalHazardCache,
                                    icon: const Icon(Icons.delete_outline),
                                    label:
                                        const Text('Clear local hazard cache'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Privacy information',
                            subtitle:
                                'How RoadGuard handles sensor, location, and detection data.',
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'RoadGuard stores hazard detections locally first so core safety features continue to work without network access.',
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'When cloud sync is enabled, pending events can be uploaded later for backup, multi-device continuity, and collaborative hazard mapping.',
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'If data sharing is enabled, only the minimum road-improvement data needed for aggregated analysis should be shared by future sync services.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_controller.isSaving)
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              title: Text('Saving settings locally...'),
                            ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmClearLocalHazardCache() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear local hazard cache?'),
          content: const Text(
            'This removes locally stored hazard detections from the device. Synced cloud data will not be restored here automatically.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _controller.clearLocalHazardCache();
  }

  void _handleControllerChanged() {
    final String? message = _controller.statusMessage;

    if (message == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    _controller.clearStatusMessage();
  }

  static String _sensitivityLabel(AlertSensitivity sensitivity) {
    switch (sensitivity) {
      case AlertSensitivity.low:
        return 'Low';
      case AlertSensitivity.normal:
        return 'Normal';
      case AlertSensitivity.high:
        return 'High';
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
