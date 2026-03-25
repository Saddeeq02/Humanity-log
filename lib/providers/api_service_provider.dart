import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  // Use compile-time environment override if provided, otherwise use a live default.
  // To override at build time: flutter build apk --dart-define=API_BASE_URL=https://your-backend
  const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  final baseUrl = envUrl.isNotEmpty ? envUrl : 'http://10.0.2.2:8000';
  return ApiService(baseUrl: baseUrl);
});
