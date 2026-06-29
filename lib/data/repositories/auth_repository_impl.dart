import 'package:simple_quizlet_mobile_app/data/datasources/auth_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/user_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  AuthRepositoryImpl(this._dataSource);

  @override
  Future<UserEntity> login(String email, String password) =>
      _dataSource.login(email, password);

  @override
  Future<UserEntity> register(String email, String password, String username) =>
      _dataSource.register(email, password, username);

  @override
  Future<void> logout() => _dataSource.logout();

  @override
  Future<UserEntity?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  Stream<UserEntity?> get authStateChanges => _dataSource.authStateChanges;
}
