import 'package:uuid/uuid.dart';

class DistributionLog {
  final String id;
  final String? assignmentId; // Added for backend verification
  final String beneficiaryId;
  final DateTime timestamp;
  final String aidType;
  final bool isSynced;
  final String? photoPath;
  final String? locationCoordinate;

  const DistributionLog({
    required this.id,
    this.assignmentId,
    required this.beneficiaryId,
    required this.timestamp,
    required this.aidType,
    this.isSynced = false,
    this.photoPath,
    this.locationCoordinate,
  });

  factory DistributionLog.create({
    String? assignmentId,
    required String beneficiaryId,
    required String aidType,
    String? photoPath,
    String? locationCoordinate,
  }) {
    return DistributionLog(
      id: const Uuid().v4(),
      assignmentId: assignmentId,
      beneficiaryId: beneficiaryId,
      timestamp: DateTime.now(),
      aidType: aidType,
      isSynced: false,
      photoPath: photoPath,
      locationCoordinate: locationCoordinate,
    );
  }

  DistributionLog copyWith({
    bool? isSynced,
    String? photoPath,
    String? locationCoordinate,
    String? assignmentId,
  }) {
    return DistributionLog(
      id: id,
      assignmentId: assignmentId ?? this.assignmentId,
      beneficiaryId: beneficiaryId,
      timestamp: timestamp,
      aidType: aidType,
      isSynced: isSynced ?? this.isSynced,
      photoPath: photoPath ?? this.photoPath,
      locationCoordinate: locationCoordinate ?? this.locationCoordinate,
    );
  }
}
