import 'package:go_router/go_router.dart';

import '../../features/navigation/main_navigation_page.dart';
import '../../features/splash/splash_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: "/splash",
  routes: [
    GoRoute(
      path: "/splash",
      builder: (_, _) {
        return const SplashPage();
      },
    ),
    GoRoute(
      path: "/",
      builder: (_, _) {
        return const MainNavigationPage();
      },
    ),
  ],
);
