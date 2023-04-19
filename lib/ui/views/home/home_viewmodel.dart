import 'package:auth_test/app/app.locator.dart';
import 'package:auth_test/app/app.router.dart';
import 'package:auth_test/models/user.dart';
import 'package:auth_test/services/firebase_api_service.dart';
import 'package:auth_test/services/firebase_authentication_service.dart';
import 'package:auth_test/services/user_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final _firebaseAuthService = FirebaseAuthenticationService();
  final _firebaseApiService = FirebaseApiService();
  final _userService = UserService();

  bool get hasGoogleAccount => _firebaseAuthService.hasGoogleAccount;
  bool get hasAppleAccount => _firebaseAuthService.hasAppleAccount;
  bool get hasEmailPasswordAccount =>
      _firebaseAuthService.hasEmailPasswordAccount;
  Future<void> signinWithGoogle() async {
    final result = await runBusyFuture(
      _firebaseAuthService.signInWithGoogle(),
      throwException: true,
    );
    if (result.hasError) {
      return print(result.errorMessage);
    }
    await _userService.initialize();
    final user = _userService.currentUser.copyWith(
      email: result.user?.email,
      address: const Address(
        city: 'New York',
        street: 'Wall Street',
        location: Location(
          lat: 40.7128,
          lng: 74.0060,
        ),
      ),
    );
    _firebaseApiService.updateUser(user);
  }

  void signinWithApple() {
    runBusyFuture(
      _firebaseAuthService.signInWithApple(
        appleClientId: 'np.com.saileshdahal.authTest',
        appleRedirectUri:
            'https://instagram-clone-course-sailesh.firebaseapp.com/__/auth/handler',
      ),
      throwException: true,
    );
  }

  Future<void> logout() async {
    await _firebaseAuthService.logout();
    notifyListeners();
    return locator<NavigationService>().replaceWithAuthView();
  }

  String _email = '';
  void updateEmail(String value) {
    _email = value;
  }

  String _password = '';
  void updatePassword(String value) {
    _password = value;
  }

  Future<void> signinWithEmail() async {
    final result = await runBusyFuture(
      _firebaseAuthService.signInWithEmailPassword(
        email: _email,
        password: _password,
      ),
    );
    if (result.hasError) return print(result.errorMessage);
    await _userService.initialize();
    final user = _userService.currentUser.copyWith(
      email: result.user?.email,
      address: const Address(
        city: 'New York',
        street: 'Wall Street',
        location: Location(
          lat: 40.7128,
          lng: 74.0060,
        ),
      ),
    );
    _firebaseApiService.updateUser(user);
  }
}
