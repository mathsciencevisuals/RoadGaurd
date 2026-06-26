import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../hazard_map/application/hazard_map_controller.dart';
import 'manual_hazard_report_screen.dart';

class HazardMapScreen extends StatefulWidget {
  const HazardMapScreen({
    super.key,
    this.controller,
  });

  final HazardMapController? controller;

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  late final HazardMapController _controller;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? HazardMapController();
    _controller.addListener(_handleControllerUpdate);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _mapController?.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hazard Map'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          if (_controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_controller.currentLocation == null) {
            return _LocationErrorState(
              message: _controller.locationErrorMessage ??
                  'Location is unavailable for the hazard map.',
              onRetry: _controller.refreshNearbyHazards,
            );
          }

          return Stack(
            children: <Widget>[
              GoogleMap(
                initialCameraPosition: _controller.initialCameraPosition,
                markers: _controller.markers,
                myLocationEnabled: _controller.hasLocationPermission,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                zoomControlsEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _MapOverlayCard(
                  hazardCount: _controller.hazards.length,
                  isRefreshing: _controller.isRefreshing,
                ),
              ),
              Positioned(
                right: 16,
                bottom: 96,
                child: FloatingActionButton.small(
                  heroTag: 'refresh-hazards',
                  onPressed: _controller.refreshNearbyHazards,
                  child: const Icon(Icons.refresh),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: FilledButton.icon(
                  onPressed: _openManualHazardReport,
                  icon: const Icon(Icons.report_outlined),
                  label: const Text('Report Hazard Manually'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openManualHazardReport() async {
    final bool? shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ManualHazardReportScreen(),
      ),
    );

    if (shouldRefresh == true) {
      await _controller.refreshNearbyHazards();
      await _animateToCurrentLocation();
    }
  }

  Future<void> _animateToCurrentLocation() async {
    final GoogleMapController? mapController = _mapController;
    final currentLocation = _controller.currentLocation;
    if (mapController == null || currentLocation == null) {
      return;
    }

    await mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(currentLocation.latitude, currentLocation.longitude),
      ),
    );
  }

  void _handleControllerUpdate() {
    final String? message = _controller.statusMessage;
    if (!mounted || message == null || message.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    _controller.clearStatusMessage();
  }
}

class _MapOverlayCard extends StatelessWidget {
  const _MapOverlayCard({
    required this.hazardCount,
    required this.isRefreshing,
  });

  final int hazardCount;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const Icon(Icons.place_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$hazardCount nearby hazards loaded',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (isRefreshing)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationErrorState extends StatelessWidget {
  const _LocationErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Hazard map unavailable',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
