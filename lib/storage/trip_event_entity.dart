import 'package:hive/hive.dart';

class TripEventEntity {
  const TripEventEntity({
    required this.id,
    required this.tripId,
    required this.eventType,
    required this.message,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String tripId;
  final String eventType;
  final String message;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  TripEventEntity copyWith({
    String? id,
    String? tripId,
    String? eventType,
    String? message,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    bool clearLatitude = false,
    bool clearLongitude = false,
  }) {
    return TripEventEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      eventType: eventType ?? this.eventType,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      latitude: clearLatitude ? null : latitude ?? this.latitude,
      longitude: clearLongitude ? null : longitude ?? this.longitude,
    );
  }
}

class TripEventEntityAdapter extends TypeAdapter<TripEventEntity> {
  static const int adapterTypeId = 2;

  @override
  final int typeId = adapterTypeId;

  @override
  TripEventEntity read(BinaryReader reader) {
    final int fieldCount = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{};

    for (int index = 0; index < fieldCount; index++) {
      fields[reader.readByte()] = reader.read();
    }

    return TripEventEntity(
      id: fields[0] as String,
      tripId: fields[1] as String,
      eventType: fields[2] as String,
      message: fields[3] as String,
      createdAt: fields[4] as DateTime,
      latitude: fields[5] as double?,
      longitude: fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, TripEventEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.eventType)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude);
  }
}
