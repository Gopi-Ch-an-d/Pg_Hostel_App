import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isBiometricEnabled;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isBiometricEnabled = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isBiometricEnabled,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuth();
  }

  final _storage = const FlutterSecureStorage();
  final _api = ApiClient();

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    final biometric = await _storage.read(key: 'biometric_enabled');
    state = state.copyWith(isBiometricEnabled: biometric == 'true');

    if (token != null) {
      try {
        final res = await _api.get('/auth/profile');
        state = state.copyWith(user: UserModel.fromJson(res.data), isAuthenticated: true);
      } catch (_) {
        await _storage.delete(key: 'access_token');
      }
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.post('/auth/login', data: {'username': username, 'password': password});
      await _storage.write(key: 'access_token', value: res.data['access_token']);
      
      // Store credentials ONLY IF biometric is enabled later OR keep them updated
      await _storage.write(key: 'saved_username', value: username);
      await _storage.write(key: 'saved_password', value: password);

      state = state.copyWith(
        user: UserModel.fromJson(res.data['user']),
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Invalid username or password');
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: 'biometric_enabled', value: enabled.toString());
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  Future<bool> loginWithBiometrics() async {
    final username = await _storage.read(key: 'saved_username');
    final password = await _storage.read(key: 'saved_password');
    
    if (username != null && password != null) {
      return login(username, password);
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
