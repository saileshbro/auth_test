import 'package:auth_test/app/app.locator.dart';
import 'package:auth_test/app/app.router.dart';
import 'package:auth_test/services/user_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _userService = UserService();
  // Place anything here that needs to happen before we get into the application
  Future<void> runStartupLogic() async {
    final loggedIn = await _userService.initialize();
    if (!loggedIn) return _navigationService.replaceWith<void>(Routes.authView);
    return _navigationService.replaceWithHomeView();
  }
}
