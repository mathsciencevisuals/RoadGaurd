import '../storage/hazard_event_entity.dart';
import 'api_client.dart';
import 'api_result.dart';

class HazardApi {
  HazardApi({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResult<Map<String, dynamic>>> uploadHazardEvent({
    required HazardEventEntity event,
    required String deviceId,
    String? userId,
  }) {
    return _apiClient.post(
      '/api/hazards',
      data: <String, dynamic>{
        'device_id': deviceId,
        'user_id': userId,
        'hazard_type': event.hazardType,
        'risk_level': event.riskLevel,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'confidence': event.confidence,
        'estimated_distance_meters': event.estimatedDistanceMeters,
        'image_url': event.imagePath,
        'detected_at': event.detectedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchNearbyHazards({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final ApiResult<Map<String, dynamic>> result = await _apiClient.get(
      '/api/hazards/nearby',
      queryParameters: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
      },
    );

    if (result.isFailure) {
      return ApiResult<List<Map<String, dynamic>>>.failure(
        message: result.message ?? 'Nearby hazard lookup failed.',
        statusCode: result.statusCode,
      );
    }

    final List<dynamic> hazards =
        (result.data?['hazards'] as List<dynamic>? ?? <dynamic>[]);

    return ApiResult<List<Map<String, dynamic>>>.success(
      data: hazards
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
      statusCode: result.statusCode,
    );
  }

  Future<ApiResult<Map<String, dynamic>>> verifyHazard(String hazardId) {
    return _apiClient.post('/api/hazards/$hazardId/verify');
  }

  Future<ApiResult<Map<String, dynamic>>> reportFalsePositive(String hazardId) {
    return _apiClient.post('/api/hazards/$hazardId/false-positive');
  }
}
