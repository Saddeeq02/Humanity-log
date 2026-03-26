import 'package:uuid/uuid.dart';

class Beneficiary {
  final String id;
  final String name;
  final int age;
  final String location;
  final String? photoUrl;
  final String? biometrics;
  final bool isSynced;

  const Beneficiary({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    this.photoUrl,
    this.biometrics,
    this.isSynced = false,
  });

  factory Beneficiary.create({
    required String name,
    required int age,
    required String location,
    String? photoUrl,
    String? biometrics,
  }) {
    return Beneficiary(
      id: const Uuid().v4(),
      name: name,
      age: age,
      location: location,
      photoUrl: photoUrl,
      biometrics: biometrics,
      isSynced: false,
    );
  }

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      age: json['age'] ?? 0,
      location: json['location'] ?? 'Unknown',
      photoUrl: json['photo_url'],
      biometrics: json['biometrics'],
      isSynced: true, // Data from server is synced
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'location': location,
      'photo_url': photoUrl,
      'biometrics': biometrics,
    };
  }

  Beneficiary copyWith({
    String? name,
    int? age,
    String? location,
    String? photoUrl,
    String? biometrics,
    bool? isSynced,
  }) {
    return Beneficiary(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      location: location ?? this.location,
      photoUrl: photoUrl ?? this.photoUrl,
      biometrics: biometrics ?? this.biometrics,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
