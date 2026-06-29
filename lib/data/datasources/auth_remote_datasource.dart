import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String email, String password, String username);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Stream<UserEntity?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRemoteDataSourceImpl(this._auth, this._db);

  @override
  Future<UserEntity> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    if (!user.emailVerified) {
      await _auth.signOut();
      throw Exception('EMAIL_NOT_VERIFIED');
    }
    return _buildUserEntity(user);
  }

  @override
  Future<UserEntity> register(String email, String password, String username) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    // Save username to Firestore users collection
    await _db.collection('users').doc(user.uid).set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send email verification
    await user.sendEmailVerification();
    await _auth.signOut();

    return UserEntity(
      uid: user.uid,
      email: email,
      username: username,
      emailVerified: false,
    );
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _buildUserEntity(user);
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _buildUserEntity(user);
    });
  }

  Future<UserEntity> _buildUserEntity(User user) async {
    String username = user.email?.split('@').first ?? '';
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        username = doc.data()?['username'] ?? username;
      }
    } catch (_) {}
    return UserEntity(
      uid: user.uid,
      email: user.email ?? '',
      username: username,
      emailVerified: user.emailVerified,
    );
  }
}
