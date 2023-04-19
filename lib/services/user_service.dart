import 'dart:async';

import 'package:auth_test/models/user.dart';
import 'package:auth_test/services/firebase_api_service.dart';
import 'package:auth_test/services/firebase_authentication_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  factory UserService() => _instance ??= UserService._internal();
  UserService._internal();
  static UserService? _instance;
  final _firebaseAuthenticationService = FirebaseAuthenticationService();
  final _firebaseApiService = FirebaseApiService();

  late User? _currentUser;
  User get currentUser => _currentUser!;
  bool get hasLoggedInUser => _firebaseAuthenticationService.hasUser;

  Future<User> syncOrCreateUserAccount() async {
    final firebaseUserId =
        _firebaseAuthenticationService.firebaseAuth.currentUser!.uid;
    final accountExists =
        await _firebaseApiService.getUser(userId: firebaseUserId);
    if (accountExists != null) return _updateUser(accountExists);
    final user = User(id: _firebaseAuthenticationService.currentUser!.uid);
    _firebaseApiService.createUser(user: user).ignore();
    return _updateUser(user);
  }

  User _updateUser(User user) {
    _currentUser = user;
    if (_currentUser?.id == user.id) return _currentUser!;
    // Cancel the previous stream and start a new one
    _userUpdateStream?.cancel();
    _userUpdateStream = FirebaseApiService.usersCollection
        .doc(user.id)
        .snapshots()
        .listen((event) {
      if (!event.exists) return;
      _currentUser = User.fromJson(event.data()!);
    });
    return _currentUser!;
  }

  StreamSubscription<DocumentSnapshot>? _userUpdateStream;
  Future<bool> initialize() async {
    try {
      final isLoggedIn = await _firebaseAuthenticationService.isLoggedIn();
      if (!isLoggedIn) return false;
      await syncOrCreateUserAccount();
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _instance = null;
    _userUpdateStream?.cancel();
  }
}
