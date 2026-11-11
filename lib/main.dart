import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/firebase/firebase_config/firebase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'feature/home/provider/home_provider.dart';
import 'feature/image/provider/image_gallery_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(
          create: (_) => ImageGalleryProvider()..initRealtimeImages(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Assignment 2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
