import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../risk/risk_level.dart';
import '../application/driver_mode_controller.dart';

class DriverModeScreen extends StatefulWidget {
  const DriverModeScreen({
    super.key,
    this.controller,
  });

  final DriverModeController? controller;

  @override
  State<DriverModeScreen> createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends State<DriverModeScreen> {
  late final DriverModeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DriverModeController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = Theme.of(context);
    final ThemeData screenTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: const Color(0xFF060B12),
      cardColor: const Color(0xFF121A24),
      colorScheme: baseTheme.colorScheme.copyWith(
        surface: const Color(0xFF121A24),
        primary: const Color(0xFF64E8B8),
        onPrimary: Colors.black,
      ),
    );

    return Theme(
      data: screenTheme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Driver Mode'),
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  _CurrentStatusCard(controller: _controller),
                  const SizedBox(height: 16),
                  _RiskStatusCard(riskLevel: _controller.currentRiskLevel),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: _controller.toggleDetection,
                      child: Text(
                        _controller.isDetectionActive
                            ? 'Stop Detection'
                            : 'Start Detection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SecondaryActionButton(
                    label: 'View Hazard Map',
                    icon: Icons.map_outlined,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.map),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionButton(
                    label: 'Trip Summary',
                    icon: Icons.summarize_outlined,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.summary),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionButton(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({
    required this.controller,
  });

  final DriverModeController controller;

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
              'Current Status',
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _StatusRow(
              label: 'RoadGuard',
              value: controller.isDetectionActive ? 'Active' : 'Inactive',
            ),
            _StatusRow(
              label: 'GPS',
              value: controller.gpsStatus == GpsStatus.active
                  ? 'Active'
                  : 'Waiting',
            ),
            _StatusRow(
              label: 'Camera',
              value: controller.cameraStatus == CameraStatus.ready
                  ? 'Ready'
                  : 'Not Ready',
            ),
            _StatusRow(
              label: 'Current speed',
              value: '${controller.currentSpeedKmph.toStringAsFixed(0)} km/h',
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskStatusCard extends StatelessWidget {
  const _RiskStatusCard({
    required this.riskLevel,
  });

  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    final Color color = _riskColor(riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Active Risk Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Text(
                _riskLabel(riskLevel),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _riskLabel(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.none:
        return 'NONE';
      case RiskLevel.low:
        return 'LOW';
      case RiskLevel.medium:
        return 'MEDIUM';
      case RiskLevel.high:
        return 'HIGH';
      case RiskLevel.critical:
        return 'CRITICAL';
    }
  }

  static Color _riskColor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.none:
        return const Color(0xFF9AA7B8);
      case RiskLevel.low:
        return const Color(0xFF5DE2A5);
      case RiskLevel.medium:
        return const Color(0xFFFFC857);
      case RiskLevel.high:
        return const Color(0xFFFF8A5B);
      case RiskLevel.critical:
        return const Color(0xFFFF4D6D);
    }
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          side: const BorderSide(color: Color(0xFF2A3746)),
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
