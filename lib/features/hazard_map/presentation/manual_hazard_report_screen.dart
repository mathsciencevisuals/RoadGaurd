import 'package:flutter/material.dart';

import '../../hazard_map/application/manual_hazard_report_controller.dart';

class ManualHazardReportScreen extends StatefulWidget {
  const ManualHazardReportScreen({
    super.key,
    this.controller,
  });

  final ManualHazardReportController? controller;

  @override
  State<ManualHazardReportScreen> createState() =>
      _ManualHazardReportScreenState();
}

class _ManualHazardReportScreenState extends State<ManualHazardReportScreen> {
  late final ManualHazardReportController _controller;
  late final TextEditingController _noteController;
  bool _shouldRefreshOnExit = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ManualHazardReportController();
    _noteController = TextEditingController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _noteController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_shouldRefreshOnExit);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manual Hazard Report'),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) {
            final bool hasLocation = _controller.currentLocation != null;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text(
                  'Report a road hazard',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Reports are saved locally first and uploaded to the backend when available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (_controller.statusMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _StatusBanner(
                    message: _controller.statusMessage!,
                    status: _controller.status,
                  ),
                ],
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Hazard Type',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        ManualHazardType.values.map((ManualHazardType type) {
                      final bool isSelected =
                          _controller.selectedHazardType == type;
                      return ChoiceChip(
                        label: Text(_labelForType(type)),
                        selected: isSelected,
                        onSelected: (_) => _controller.setHazardType(type),
                      );
                    }).toList(growable: false),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Current Location',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (hasLocation)
                        Text(
                          'Lat ${_controller.currentLocation!.latitude.toStringAsFixed(6)}, '
                          'Lng ${_controller.currentLocation!.longitude.toStringAsFixed(6)}',
                        )
                      else
                        const Text(
                          'Current GPS location is not available yet.',
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _controller.isLoadingLocation
                            ? null
                            : _controller.refreshLocation,
                        icon: const Icon(Icons.my_location_outlined),
                        label: Text(
                          _controller.isLoadingLocation
                              ? 'Refreshing...'
                              : 'Refresh Location',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Optional Note',
                  child: TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe what you observed',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _controller.setNote,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Optional Photo',
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _controller.photoPlaceholderLabel ??
                              'Photo capture will be added later.',
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _controller.setPhotoPlaceholderLabel(
                          'photo-placeholder',
                        ),
                        child: const Text('Add Placeholder'),
                      ),
                    ],
                  ),
                ),
                if (_controller.validationMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    _controller.validationMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _controller.isSubmitting
                        ? null
                        : (_shouldRefreshOnExit
                            ? _closeWithRefresh
                            : _submitManualReport),
                    child: _controller.isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _shouldRefreshOnExit
                                ? 'Done'
                                : 'Submit Hazard Report',
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitManualReport() async {
    final bool submitted = await _controller.submitReport();
    if (!mounted || !submitted) {
      return;
    }
    setState(() {
      _shouldRefreshOnExit = true;
    });
  }

  void _closeWithRefresh() {
    Navigator.of(context).pop(true);
  }

  String _labelForType(ManualHazardType type) {
    switch (type) {
      case ManualHazardType.pothole:
        return 'Pothole';
      case ManualHazardType.roadHump:
        return 'Road Hump';
      case ManualHazardType.waterLogging:
        return 'Water Logging';
      case ManualHazardType.obstacle:
        return 'Obstacle';
      case ManualHazardType.accidentRisk:
        return 'Accident Risk';
      case ManualHazardType.pedestrianRisk:
        return 'Pedestrian Risk';
      case ManualHazardType.other:
        return 'Other';
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.status,
  });

  final String message;
  final ManualHazardReportStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    late final Color backgroundColor;
    late final Color foregroundColor;

    if (status == ManualHazardReportStatus.success) {
      backgroundColor = Colors.green.shade100;
      foregroundColor = Colors.green.shade900;
    } else if (status == ManualHazardReportStatus.partialSuccess) {
      backgroundColor = Colors.orange.shade100;
      foregroundColor = Colors.orange.shade900;
    } else if (status == ManualHazardReportStatus.failure) {
      backgroundColor = colorScheme.errorContainer;
      foregroundColor = colorScheme.onErrorContainer;
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest;
      foregroundColor = colorScheme.onSurfaceVariant;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: TextStyle(color: foregroundColor),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
