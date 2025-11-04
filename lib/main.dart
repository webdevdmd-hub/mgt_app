import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mgt_app/firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  //   DeviceOrientation.landscapeLeft,
  //   DeviceOrientation.landscapeRight,
  // ]);

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setPathUrlStrategy();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: 'DMD APP',
      theme: ThemeData.light(),
    );
  }
}

// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // final router = ref.watch(appRouterProvider); // <--- REMOVE THIS

//     return MaterialApp(
//       // <--- Change from MaterialApp.router to MaterialApp
//       debugShowCheckedModeBanner: false,
//       // routerConfig: router, // <--- REMOVE THIS

//       // 2. Set the 'home' property to your main screen
//       home: const AdminPanelScreen(), // <--- SET YOUR DASHBOARD AS HOME

//       title: 'MGT App',
//     );
//   }
// }
