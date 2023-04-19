import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthenticationService {
  factory FirebaseAuthenticationService() =>
      _instance ??= FirebaseAuthenticationService._internal();
  FirebaseAuthenticationService._internal();
  static FirebaseAuthenticationService? _instance;
  final firebaseAuth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  Future<UserCredential> _signInWithCredential(AuthCredential credential) {
    if (currentUser != null) return currentUser!.linkWithCredential(credential);
    return firebaseAuth.signInWithCredential(credential);
  }

  /// Returns the current logged in Firebase User
  User? get currentUser => firebaseAuth.currentUser;
  // bool get isAnonymous => firebaseAuth.currentUser?.isAnonymous ?? false;
  List<UserInfo> get _providers => currentUser?.providerData ?? [];

  bool get hasGoogleAccount =>
      _providers.where((e) => e.providerId == 'google.com').isNotEmpty;
  bool get hasAppleAccount =>
      _providers.where((e) => e.providerId == 'apple.com').isNotEmpty;
  bool get hasEmailPasswordAccount =>
      _providers.where((e) => e.providerId == 'password').isNotEmpty;

  Future<bool> isLoggedIn() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) return false;
      await currentUser.getIdToken();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns the latest userToken stored in the Firebase Auth lib
  Future<String>? get userToken => firebaseAuth.currentUser?.getIdToken();

  /// Returns true when a user has logged in or signed on this device
  bool get hasUser => firebaseAuth.currentUser != null;

  /// Exposes the authStateChanges functionality.
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      return;
    }
  }

  /// Returns `true` when email has a user registered
  Future<bool> emailExists(String email) async {
    try {
      final signInMethods =
          await firebaseAuth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } on FirebaseAuthException catch (e) {
      return e.code.toLowerCase() == 'invalid-email';
    }
  }

  Future<FirebaseAuthenticationResult> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      /// On the web, the Firebase SDK provides support for automatically
      /// handling the authentication flow.
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()
          ..setCustomParameters({'login_hint': 'user@example.com'});
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      }

      /// On native platforms, a 3rd party library, like GoogleSignIn, is
      /// required to trigger the authentication flow.
      else {
        final googleSignInAccount = await _googleSignIn.signIn();
        if (googleSignInAccount == null) {
          return FirebaseAuthenticationResult.error(
            errorMessage: 'Google Sign In has been canceled by the user',
            exceptionCode: 'canceled',
          );
        }
        final googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        userCredential = await _signInWithCredential(credential);
      }

      return FirebaseAuthenticationResult(
        user: userCredential.user,
        additionalUserInfo: userCredential.additionalUserInfo,
      );
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthenticationResult.error(
        errorMessage: getErrorMessageFromFirebaseException(e),
        exceptionCode: e.code,
      );
    } catch (e) {
      return FirebaseAuthenticationResult.error(errorMessage: e.toString());
    }
  }

  Future<bool> isAppleSignInAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Apple will reject your app if you ask for the name when you sign in, but do not use it in the app.
  /// To prevent this, set askForFullName to false.
  Future<FirebaseAuthenticationResult> signInWithApple({
    required String? appleRedirectUri,
    required String? appleClientId,
    bool askForFullName = true,
  }) async {
    try {
      if (appleClientId == null) {
        throw FirebaseAuthException(
          message:
              'If you want to use Apple Sign In you have to provide a appleClientId to the FirebaseAuthenticationService',
          code: 'apple-client-id-missing',
        );
      }

      if (appleRedirectUri == null) {
        throw FirebaseAuthException(
          message:
              'If you want to use Apple Sign In you have to provide a appleRedirectUri to the FirebaseAuthenticationService',
          code: 'apple-redirect-uri-missing',
        );
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          if (askForFullName) AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: appleClientId,
          redirectUri: Uri.parse(appleRedirectUri),
        ),
        nonce: nonce,
      );

      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleIdCredential.identityToken,
        accessToken: appleIdCredential.authorizationCode,
        rawNonce: rawNonce,
      );
      final appleCredential = await _signInWithCredential(credential);
      if (askForFullName) {
        // Update the display name using the name from
        final givenName = appleIdCredential.givenName;
        final hasGivenName = givenName != null;
        final familyName = appleIdCredential.familyName;
        final hasFamilyName = familyName != null;
        await appleCredential.user?.updateDisplayName(
          '${hasGivenName ? givenName : ''}${hasFamilyName ? ' $familyName' : ''}',
        );
      }

      return FirebaseAuthenticationResult(
        user: appleCredential.user,
        additionalUserInfo: appleCredential.additionalUserInfo,
      );
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthenticationResult.error(
        errorMessage: getErrorMessageFromFirebaseException(e),
        exceptionCode: e.code,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      return FirebaseAuthenticationResult.error(
        errorMessage: e.toString(),
        exceptionCode: e.code.name,
      );
    } catch (e) {
      return FirebaseAuthenticationResult.error(errorMessage: e.toString());
    }
  }

  /// Anonymous Login
  Future<FirebaseAuthenticationResult> signInAnonymously() async {
    try {
      final result = await firebaseAuth.signInAnonymously();
      return FirebaseAuthenticationResult(
        user: result.user,
        additionalUserInfo: result.additionalUserInfo,
      );
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthenticationResult.error(
        exceptionCode: e.code.toLowerCase(),
        errorMessage: getErrorMessageFromFirebaseException(e),
      );
    } on Exception {
      return FirebaseAuthenticationResult.error(
        errorMessage:
            'We could not log into your account at this time. Please try again.',
      );
    }
  }

  Future<FirebaseAuthenticationResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credentials =
          EmailAuthProvider.credential(email: email, password: password);
      // link to existing account if exists
      if (currentUser != null) {
        final userCreds = await currentUser!.linkWithCredential(credentials);
        return FirebaseAuthenticationResult(
          user: userCreds.user,
          additionalUserInfo: userCreds.additionalUserInfo,
        );
      }
      final result = await firebaseAuth.signInWithCredential(credentials);
      return FirebaseAuthenticationResult(
        user: result.user,
        additionalUserInfo: result.additionalUserInfo,
      );
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthenticationResult.error(
        exceptionCode: e.code.toLowerCase(),
        errorMessage: getErrorMessageFromFirebaseException(e),
      );
    } on Exception {
      return FirebaseAuthenticationResult.error(
        errorMessage:
            'We could not log into your account at this time. Please try again.',
      );
    }
  }

  // Signup with email and password
  Future<FirebaseAuthenticationResult> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return FirebaseAuthenticationResult(
        user: result.user,
        additionalUserInfo: result.additionalUserInfo,
      );
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthenticationResult.error(
        exceptionCode: e.code.toLowerCase(),
        errorMessage: getErrorMessageFromFirebaseException(e),
      );
    } on Exception {
      return FirebaseAuthenticationResult.error(
        errorMessage:
            'We could not create your account at this time. Please try again.',
      );
    }
  }

  /// Send reset password link to email
  Future<bool> sendResetPasswordLink(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  // check if the password given by user is valid
  Future<FirebaseAuthenticationResult> validatePassword(String password) async {
    try {
      final authCredentials = EmailAuthProvider.credential(
        email: firebaseAuth.currentUser?.email ?? '',
        password: password,
      );

      final authResult = await firebaseAuth.currentUser
          ?.reauthenticateWithCredential(authCredentials);

      return FirebaseAuthenticationResult(
        user: authResult?.user,
        additionalUserInfo: authResult?.additionalUserInfo,
      );
    } catch (e) {
      return FirebaseAuthenticationResult.error(
        errorMessage: 'The current password is not valid.',
      );
    }
  }

  /// Update the [password] of the Firebase User
  Future<FirebaseAuthenticationResult> updatePassword(String password) async {
    try {
      await firebaseAuth.currentUser?.updatePassword(password);
      return FirebaseAuthenticationResult(user: firebaseAuth.currentUser);
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthenticationResult.error(
        exceptionCode: e.code.toLowerCase(),
        errorMessage: getErrorMessageFromFirebaseException(e),
      );
    } on Exception {
      return FirebaseAuthenticationResult.error(
        errorMessage:
            'Unable to update password at this time. Please try again.',
      );
    }
  }

  /// Update the [email] of the Firebase User
  Future<FirebaseAuthenticationResult> updateEmail(String email) async {
    try {
      await firebaseAuth.currentUser?.updateEmail(email);
      return FirebaseAuthenticationResult(user: firebaseAuth.currentUser);
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthenticationResult.error(
        exceptionCode: e.code.toLowerCase(),
        errorMessage: getErrorMessageFromFirebaseException(e),
      );
    } on Exception {
      return FirebaseAuthenticationResult.error(
        errorMessage: 'Unable to update email at this time. Please try again.',
      );
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class FirebaseAuthenticationResult {
  FirebaseAuthenticationResult({this.user, this.additionalUserInfo})
      : errorMessage = null,
        exceptionCode = null;
  FirebaseAuthenticationResult.error({this.errorMessage, this.exceptionCode})
      : user = null,
        additionalUserInfo = null;

  final User? user;
  final AdditionalUserInfo? additionalUserInfo;
  final String? errorMessage;
  final String? exceptionCode;

  /// Returns true if the response has an error associated with it
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

String getErrorMessageFromFirebaseException(FirebaseAuthException exception) {
  switch (exception.code.toLowerCase()) {
    case 'email-already-in-use':
      return "An account already exists for the email you're trying to use. Login instead.";
    case 'invalid-email':
      return "The email you're using is invalid. Please use a valid email.";
    case 'operation-not-allowed':
      return 'The authentication is not enabled on Firebase. Please enable the Authentication type on Firebase';
    case 'weak-password':
      return 'Your password is too weak. Please use a stronger password.';
    case 'wrong-password':
      return 'You seemed to have entered the wrong password. Double check it and try again.';
    default:
      return exception.message ??
          'Something went wrong on our side. Please try again';
  }
}
