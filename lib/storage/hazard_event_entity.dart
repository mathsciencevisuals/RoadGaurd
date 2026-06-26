import 'package:hive/hive.dart';

class HazardEventEntity {
  const HazardEventEntity({
    required this.id,
    required this.hazardType,
    required this.riskLevel,
    required this.latitude,
    required this.longitude,
    required this.confidence,
    required this.estimatedDistanceMeters,
    required this.detectedAt,
    required this.syncedToCloud,
    this.imagePath,
  });

  final String id;
  final String hazardType;
  final String riskLevel;
  final double latitude;
  final double longitude;
  final double confidence;
  final double estimatedDistanceMeters;
  final DateTime detectedAt;
  final bool syncedToCloud;
  final String? imagePath;

  HazardEventEntity copyWith({
    String? id,
    String? hazardType,
    String? riskLevel,
    double? latitude,
    double? longitude,
    double? confidence,
    double? estimatedDistanceMeters,
    DateTime? detectedAt,
    bool? syncedToCloud,
    String? imagePath,
    bool clearImagePath = false,
  }) {
    return HazardEventEntity(
      id: id ?? this.id,
      hazardType: hazardType ?? this.hazardType,
      riskLevel: riskLevel ?? this.riskLevel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      confidence: confidence ?? this.confidence,
      estimatedDistanceMeters:
          estimatedDistanceMeters ?? this.estimatedDistanceMeters,
      detectedAt: detectedAt ?? this.detectedAt,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
    );
  }
}

class HazardEventEntityAdapter extends TypeAdapter<HazardEventEntity> {
  static const int adapterTypeId = 1;

  @override
  final int typeId = adapterTypeId;

  @override
  HazardEventEntity read(BinaryReader reader) {
    final int fieldCount = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{};

    for (int index = 0; index < fieldCount; index++) {
      fields[reader.readByte()] = reader.read();
    }

    return HazardEventEntity(
      id: fields[0] as String,
      hazardType: fields[1] as String,
      riskLevel: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      confidence: fields[5] as double,
      estimatedDistanceMeters: fields[6] as double,
      detectedAt: fields[7] as DateTime,
      syncedToCloud: fields[8] as bool,
      imagePath: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HazardEventEntity obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hazardType)
      ..writeByte(2)
      ..write(obj.riskLevel)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.confidence)
      ..writeByte(6)
      ..write(obj.estimatedDistanceMeters)
      ..writeByte(7)
      ..write(obj.detectedAt)
      ..writeByte(8)
      ..write(obj.syncedToCloud)
      ..writeByte(9)
      ..write(obj.imagePath);
  }
}
