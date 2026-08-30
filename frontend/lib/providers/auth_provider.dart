import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../core/services/auth_service.dart';
import '../models/auth_model.dart';
import 'settings_provider.dart';
import 'category_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final settings = ref.watch(settingsProvider);
  final authService = ref.watch(authServiceProvider);
  return ApiClient(
    baseUrl: settings.backendUrl,
    authService: authService,
  );
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final AuthService _authService;
  final ApiClient _apiClient;

  AuthNotifier(this._ref, this._authService, this._apiClient)
      : super(AuthState(
          isAuthenticated: _authService.isAuthenticated,
          user: _authService.currentUser,
        ));

  Future<bool> login(String emailOrUsername, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _apiClient.login(
      emailOrUsername: emailOrUsername,
      password: password,
    );

    if (result.isSuccess) {
      final auth = result.dataOrNull!;
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: auth.user,
      );
      // Sync categories with authenticated user
      await _ref.read(categoryListProvider.notifier).syncRemote();
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorOrNull ?? 'Login failed',
      );
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _apiClient.register(
      username: username,
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      final auth = result.dataOrNull!;
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: auth.user,
      );
      // Sync categories with authenticated user
      await _ref.read(categoryListProvider.notifier).syncRemote();
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorOrNull ?? 'Registration failed',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.logout();
    await _authService.clearAuth();
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
      user: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(ref, authService, apiClient);
});
