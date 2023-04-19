import 'package:auth_test/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

mixin Collections {
  static const String users = 'users';
}

class FirebaseApiService {
  factory FirebaseApiService() => _instance ??= FirebaseApiService._internal();
  FirebaseApiService._internal();
  static FirebaseApiService? _instance;

  static final usersCollection =
      FirebaseFirestore.instance.collection(Collections.users);

  Future<void> createUser({required User user}) async {
    try {
      final userDocument = usersCollection.doc(user.id);
      await userDocument.set(user.toJson());
    } catch (error) {
      throw FirestoreApiException(
        message: 'Failed to create new user',
        devDetails: '$error',
      );
    }
  }

  Future<User?> getUser({required String userId}) async {
    if (userId.isEmpty) {
      throw FirestoreApiException(
        message:
            'Your userId passed in is empty. Please pass in a valid user if from your Firebase user.',
      );
    }
    final userDoc = await usersCollection.doc(userId).get();
    if (!userDoc.exists) return null;
    final userData = userDoc.data();
    return User.fromJson(userData!);
  }

  Future<User?> updateUser(User user) async {
    try {
      final userDocument = usersCollection.doc(user.id);
      await userDocument.update(user.toJson());
      return user;
    } catch (error) {
      throw FirestoreApiException(
        message: 'Failed to update user',
        devDetails: '$error',
      );
    }
  }
}

class FirestoreApiException implements Exception {
  FirestoreApiException({
    required this.message,
    this.devDetails,
    this.prettyDetails,
  });
  final String message;
  final String? devDetails;
  final String? prettyDetails;

  @override
  String toString() {
    return 'FirestoreApiException: $message ${devDetails != null ? '- $devDetails' : ''}';
  }
}
