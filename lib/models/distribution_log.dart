import 'package:uuid/uuid.dart';

class DistributionLog {
  final String id;
  final String? assignmentId;
  final String beneficiaryId;
  final String agentId;
  final DateTime timestamp;
  final String aidType;
  final bool isSynced;
  final String? photoPath;
  final String? locationCoordinate;

  const DistributionLog({
    required this.id,
    this.assignmentId,
    required this.beneficiaryId,
    required this.agentId,
    required this.timestamp,
    required this.aidType,
    this.isSynced = false,
    this.photoPath,
    this.locationCoordinate,
  });

  factory DistributionLog.create({
    required String assignmentId,
    required String beneficiaryId,
    required String agentId,
    required String aidType,
    String? photoPath,
    String? locationCoordinate,
  }) {
    return DistributionLog(
      id: const Uuid().v4(),
      assignmentId: assignmentId,
      beneficiaryId: beneficiaryId,
      agentId: agentId,
      timestamp: DateTime.now(),
      aidType: aidType,
      isSynced: false,
      photoPath: photoPath,
      locationCoordinate: locationCoordinate,
    );
  }

  factory DistributionLog.fromJson(Map<String, dynamic> json) {
    return DistributionLog(
      id: json['id'],
      assignmentId: json['assignment_id'],
      beneficiaryId: json['beneficiary_id'],
      agentId: json['agent_id'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      aidType: json['aid_type'] ?? 'General',
      isSynced: json['is_synced'] ?? true,
      photoPath: json['photo_path'],
      locationCoordinate: json['location_coordinate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'beneficiary_id': beneficiaryId,
      'agent_id': agentId,
      'timestamp': timestamp.toIso8601String(),
      'aid_type': aidType,
      'location_coordinate': locationCoordinate ?? '',
      'evidence': photoPath != null ? {
        'id': '$id-evidence',
        'photo_url': photoPath,
        'gps_verification_status': 'verified'
      } : null,
    };
  }

  DistributionLog copyWith({
    bool? isSynced,
    String? photoPath,
    String? locationCoordinate,
    String? assignmentId,
    String? agentId,
  }) {
    return DistributionLog(
      id: id,
      assignmentId: assignmentId ?? this.assignmentId,
      beneficiaryId: beneficiaryId,
      agentId: agentId ?? this.agentId,
      timestamp: timestamp,
      aidType: aidType,
      isSynced: isSynced ?? this.isSynced,
      photoPath: photoPath ?? this.photoPath,
      locationCoordinate: locationCoordinate ?? this.locationCoordinate,
    );
  }
}
