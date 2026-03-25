import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user.dart';
import 'api_service_provider.dart';
import 'sync_provider.dart';

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({AuthUser? user, bool? isLoading, String? error, bool clearError = false}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.login(email, password);
      
      final user = AuthUser.fromJson(
        response['user'], 
        token: response['access_token']
      );
      
      state = state.copyWith(user: user, isLoading: false);
      
      // Trigger initial sync after login
      ref.read(networkProvider.notifier).initialSync();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> loginWithBiometrics() async {
    // Biometric mock - in a real app this would also verify with backend
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(seconds: 1));

    final user = AuthUser(
      id: 'agent-007-mock',
      name: 'James Bond',
      email: 'agent007@humanitylog.org',
      role: 'agent',
    );
    state = state.copyWith(user: user, isLoading: false);
    return true;
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
