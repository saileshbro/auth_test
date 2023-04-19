import 'package:auth_test/services/firebase_api_service.dart';
import 'package:auth_test/services/firebase_authentication_service.dart';
import 'package:auth_test/services/user_service.dart';
import 'package:auth_test/ui/views/auth/auth_view.dart';
import 'package:auth_test/ui/views/home/home_view.dart';
import 'package:auth_test/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: AuthView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton<BottomSheetService>(classType: BottomSheetService),
    LazySingleton<DialogService>(classType: DialogService),
    LazySingleton<NavigationService>(classType: NavigationService),
    LazySingleton<FirebaseAuthenticationService>(
      classType: FirebaseAuthenticationService,
    ),
    LazySingleton<FirebaseApiService>(classType: FirebaseApiService),
    LazySingleton<UserService>(classType: UserService),
    // @stacked-service
  ],
)
class App {}
