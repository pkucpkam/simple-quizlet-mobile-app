import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/user_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/auth_usecases.dart';

// ── Events ────────────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String email, password;
  AuthLoginRequested(this.email, this.password);
  @override List<Object?> get props => [email, password];
}
class AuthRegisterRequested extends AuthEvent {
  final String email, password, username;
  AuthRegisterRequested(this.email, this.password, this.username);
  @override List<Object?> get props => [email, password, username];
}
class AuthLogoutRequested extends AuthEvent {}

// ── States ────────────────────────────────────────────────────────
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}
class AuthRegistered extends AuthState {} // Register success - need verify email

// ── BLoC ──────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _getCurrentUserUseCase.call();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _loginUseCase.call(event.email, event.password);
      emit(AuthAuthenticated(user));
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == 'EMAIL_NOT_VERIFIED') {
        emit(AuthError('EMAIL_NOT_VERIFIED'));
      } else {
        emit(AuthError(_mapFirebaseError(msg)));
      }
    }
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _registerUseCase.call(event.email, event.password, event.username);
      emit(AuthRegistered());
    } on Exception catch (e) {
      emit(AuthError(_mapFirebaseError(e.toString())));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _logoutUseCase.call();
    emit(AuthUnauthenticated());
  }

  String _mapFirebaseError(String msg) {
    if (msg.contains('user-not-found') || msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Email hoặc mật khẩu không đúng!';
    }
    if (msg.contains('email-already-in-use')) return 'Email đã được sử dụng!';
    if (msg.contains('weak-password')) return 'Mật khẩu phải có ít nhất 6 ký tự!';
    if (msg.contains('invalid-email')) return 'Email không hợp lệ!';
    if (msg.contains('too-many-requests')) return 'Quá nhiều lần thử. Vui lòng thử lại sau!';
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}
