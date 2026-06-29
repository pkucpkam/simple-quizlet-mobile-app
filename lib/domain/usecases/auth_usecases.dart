import 'package:simple_quizlet_mobile_app/domain/entities/user_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<UserEntity> call(String email, String password) =>
      _repository.login(email, password);
}

class RegisterUseCase {
  final AuthRepository _repository;
  RegisterUseCase(this._repository);

  Future<UserEntity> call(String email, String password, String username) =>
      _repository.register(email, password, username);
}

class LogoutUseCase {
  final AuthRepository _repository;
  LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}

class GetCurrentUserUseCase {
  final AuthRepository _repository;
  GetCurrentUserUseCase(this._repository);

  Future<UserEntity?> call() => _repository.getCurrentUser();

  Stream<UserEntity?> get authStream => _repository.authStateChanges;
}
