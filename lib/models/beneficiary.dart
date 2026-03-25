import 'package:uuid/uuid.dart';

class Beneficiary {
  final String id;
  final String name;
  final int age;
  final String location;
  final String? gpsCoordinates;
  final String? photoUrl;
  final String? biometricHash;

  const Beneficiary({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    this.gpsCoordinates,
    this.photoUrl,
    this.biometricHash,
  });

  factory Beneficiary.create({
    required String name,
    required int age,
    required String location,
    String? gpsCoordinates,
    String? photoUrl,
    String? biometricHash,
  }) {
    return Beneficiary(
      id: const Uuid().v4(),
      name: name,
      age: age,
      location: location,
      gpsCoordinates: gpsCoordinates,
      photoUrl: photoUrl,
      biometricHash: biometricHash,
    );
  }

  Beneficiary copyWith({
    String? name,
    int? age,
    String? location,
    String? gpsCoordinates,
    String? photoUrl,
    String? biometricHash,
  }) {
    return Beneficiary(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      location: location ?? this.location,
      gpsCoordinates: gpsCoordinates ?? this.gpsCoordinates,
      photoUrl: photoUrl ?? this.photoUrl,
      biometricHash: biometricHash ?? this.biometricHash,
    );
  }
}
