import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import 'cubit_status.dart';

enum AuthMode { checking, register, login, authenticated }

class AuthState {
  const AuthState({
    this.status = CubitStatus.initial,
    this.mode = AuthMode.checking,
    this.hasUsers = false,
    this.user,
    this.message,
  });

  final CubitStatus status;
  final AuthMode mode;
  final bool hasUsers;
  final UserAccount? user;
  final String? message;

  bool get isAuthenticated => mode == AuthMode.authenticated;
  bool get needsRegister => mode == AuthMode.register;
  bool get needsLogin => mode == AuthMode.login;

  AuthState copyWith({
    CubitStatus? status,
    AuthMode? mode,
    bool? hasUsers,
    UserAccount? user,
    bool clearUser = false,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      hasUsers: hasUsers ?? this.hasUsers,
      user: clearUser ? null : user ?? this.user,
      message: clearMessage ? null : message,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> checkAuthStatus() async {
    emit(
      state.copyWith(
        status: CubitStatus.loading,
        mode: AuthMode.checking,
        clearMessage: true,
      ),
    );
    try {
      final hasUsers = await _repository.hasUsers();
      if (!hasUsers) {
        emit(
          state.copyWith(
            status: CubitStatus.success,
            mode: AuthMode.register,
            hasUsers: false,
            clearUser: true,
          ),
        );
        return;
      }

      final sessionUser = await _repository.getSessionUser();
      if (sessionUser != null) {
        emit(
          state.copyWith(
            status: CubitStatus.success,
            mode: AuthMode.authenticated,
            hasUsers: true,
            user: sessionUser,
            clearMessage: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: CubitStatus.success,
            mode: AuthMode.login,
            hasUsers: true,
            clearUser: true,
            clearMessage: true,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: CubitStatus.failure,
          mode: AuthMode.login,
          hasUsers: true,
          message: 'Gagal memuat status autentikasi: $error',
        ),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: CubitStatus.loading,
        mode: AuthMode.register,
        clearMessage: true,
      ),
    );
    try {
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: CubitStatus.success,
          mode: AuthMode.authenticated,
          hasUsers: true,
          user: user,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CubitStatus.failure,
          mode: AuthMode.register,
          hasUsers: state.hasUsers,
          message: '$error'.replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: CubitStatus.loading,
        mode: AuthMode.login,
        clearMessage: true,
      ),
    );
    try {
      final user = await _repository.login(email: email, password: password);
      if (user == null) {
        emit(
          state.copyWith(
            status: CubitStatus.failure,
            mode: AuthMode.login,
            hasUsers: true,
            message: 'Email atau kata sandi tidak sesuai.',
            clearUser: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: CubitStatus.success,
          mode: AuthMode.authenticated,
          hasUsers: true,
          user: user,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CubitStatus.failure,
          mode: AuthMode.login,
          hasUsers: true,
          message: 'Gagal login: $error',
          clearUser: true,
        ),
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(
      state.copyWith(
        status: CubitStatus.success,
        mode: AuthMode.login,
        hasUsers: true,
        clearUser: true,
        clearMessage: true,
      ),
    );
  }

  void openRegister() {
    emit(
      state.copyWith(
        status: CubitStatus.success,
        mode: AuthMode.register,
        hasUsers: state.hasUsers,
        clearMessage: true,
      ),
    );
  }

  void openLogin() {
    emit(
      state.copyWith(
        status: CubitStatus.success,
        mode: AuthMode.login,
        hasUsers: true,
        clearMessage: true,
      ),
    );
  }
}
