import 'package:auth_test/app/app.locator.dart';
import 'package:auth_test/app/app.router.dart';
import 'package:auth_test/services/firebase_authentication_service.dart';
import 'package:auth_test/services/user_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class AuthViewModel extends BaseViewModel {
  final firebaseAuthService = FirebaseAuthenticationService();
  final _navigationService = locator<NavigationService>();
  final _userService = UserService();
  Future<void> signInAnonymously() async {
    final res = await runBusyFuture(firebaseAuthService.signInAnonymously());
    if (res.hasError) return print(res.errorMessage);
    _userService.initialize();
    print('Signed in anonymously');
    return _navigationService.replaceWithHomeView();
  }

  void signinWithApple() {}

  Future<void> signInWithGoogle() async {
    final res = await runBusyFuture(firebaseAuthService.signInWithGoogle());
    if (res.hasError) return print(res.errorMessage);
    _userService.initialize();
    print('Signed in with google');
    return _navigationService.replaceWithHomeView();
  }
}
