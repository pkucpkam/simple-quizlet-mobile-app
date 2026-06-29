import 'package:simple_quizlet_mobile_app/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String email, String password, String username);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Stream<UserEntity?> get authStateChanges;
}
