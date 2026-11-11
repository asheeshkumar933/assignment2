import 'package:go_router/go_router.dart';
import '../../feature/home/screen/home_screen.dart';
import '../../feature/home/screen/main_shell_screen.dart';
import '../../feature/image/screen/image_screen.dart';

class AppRouter {
  static const String uploadPath = '/upload';
  static const String imagePath = '/image';

  static final GoRouter router = GoRouter(
    initialLocation: uploadPath,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: uploadPath,
                name: 'upload',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: imagePath,
                name: 'image',
                builder: (context, state) => const ImageScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
