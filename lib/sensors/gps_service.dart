import 'package:geolocator/geolocator.dart';

import 'location_sample.dart';

enum LocationAccessState {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class GpsServiceException implements Exception {
  const GpsServiceException(this.message);

  final String message;

  @override
  String toString() => 'GpsServiceException(message: $message)';
}

class GpsService {
  const GpsService();

  Future<LocationAccessState> ensureLocationAccess() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccessState.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationAccessState.deniedForever;
    }

    if (permission == LocationPermission.denied) {
      return LocationAccessState.denied;
    }

    return LocationAccessState.granted;
  }

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Stream<ServiceStatus> observeGpsServiceStatus() {
    return Geolocator.getServiceStatusStream();
  }

  Future<LocationSample?> getCurrentLocation() async {
    final LocationAccessState accessState = await ensureLocationAccess();
    if (accessState != LocationAccessState.granted) {
      return null;
    }

    final Position position = await Geolocator.getCurrentPosition();
    return _mapPosition(position);
  }

  Stream<LocationSample> observeLocation({
    LocationSettings? locationSettings,
  }) async* {
    final LocationAccessState accessState = await ensureLocationAccess();
    if (accessState != LocationAccessState.granted) {
      throw GpsServiceException(
        _messageForAccessState(accessState),
      );
    }

    yield* Geolocator.getPositionStream(
      locationSettings: locationSettings ??
          const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 3,
          ),
    ).map(_mapPosition);
  }

  LocationSample _mapPosition(Position position) {
    return LocationSample(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      headingDegrees: position.heading,
      speedKmph: position.speed * 3.6,
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }

  String _messageForAccessState(LocationAccessState accessState) {
    switch (accessState) {
      case LocationAccessState.granted:
        return 'Location access granted.';
      case LocationAccessState.denied:
        return 'Location permission was denied.';
      case LocationAccessState.deniedForever:
        return 'Location permission is permanently denied.';
      case LocationAccessState.serviceDisabled:
        return 'GPS is disabled on this device.';
    }
  }
}
