import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/distribution_log.dart';
import '../models/beneficiary.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Authentication failed');
    }
  }

  Future<http.Response> pushSyncPayload({required String agentId, required List<DistributionLog> logs, required List<Beneficiary> newBeneficiaries}) async {
    final url = Uri.parse('$baseUrl/api/v1/sync/push');

    final body = {
      'agent_id': agentId,
      'logs': logs.map((l) => {
        'id': l.id,
        'assignment_id': l.assignmentId, 
        'beneficiary_id': l.beneficiaryId,
        'agent_id': agentId,
        'timestamp': l.timestamp.toIso8601String(),
        'location_coordinate': l.locationCoordinate ?? '',
        'evidence': l.photoPath != null ? {
          'id': l.id + '-evidence',
          'photo_url': l.photoPath,
          'gps_verification_status': 'unknown'
        } : null
      }).toList(),
      'new_beneficiaries': newBeneficiaries.map((b) => {
        'id': b.id,
        'name': b.name,
        'age': b.age,
        'location': b.location,
        'photo_url': b.photoUrl,
        'biometrics': b.biometricHash
      }).toList(),
    };

    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    return response;
  }

  Future<List<Beneficiary>> pullBeneficiaries({required String agentId}) async {
    final url = Uri.parse('$baseUrl/api/v1/sync/pull?agent_id=$agentId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final bens = <Beneficiary>[];
      if (data['beneficiaries'] != null) {
        for (var b in data['beneficiaries']) {
          bens.add(Beneficiary(
            id: b['id'],
            name: b['name'] ?? '',
            age: b['age'] ?? 0,
            location: b['location'] ?? '',
            gpsCoordinates: b['gps_coordinates'] ?? '',
            photoUrl: b['photo_url'] ?? '',
            biometricHash: b['biometric_hash'] ?? '',
          ));
        }
      }
      return bens;
    } else {
      throw Exception('Failed to pull beneficiaries: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>?> getLatestAssignment({required String userId}) async {
    final url = Uri.parse('$baseUrl/api/v1/assignments/user/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to get assignment: ${response.statusCode}');
    }
  }
}
