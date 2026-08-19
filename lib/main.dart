import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:app_links/app_links.dart';
import 'package:habit_harbor/presentation/auth/login_screen.dart';
import 'package:habit_harbor/presentation/auth/reset_password_screen.dart'; // ✅ adjust path to wherever you save it
import 'package:habit_harbor/presentation/splash_screen/splash_screen.dart';

import 'application/auth/auth_bloc.dart';
import 'application/auth/auth_event.dart';
import 'application/auth/auth_state.dart';
import 'application/goal/goal_bloc.dart';
import 'core/app/app.dart';
import 'core/injection_container/injection_container.dart';
import 'core/service/notification/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

// ✅ Global navigator key — lets the deep-link handler push routes
// without needing a BuildContext from inside the widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();

    await initializeDependencies();
    print('✅ Dependencies initialized successfully');

    runApp(const MyApp());
  } catch (e) {
    print('❌ Failed to initialize app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Failed to start app: $e'))),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle link that launched the app (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (e) {
      print('⚠️ Error getting initial deep link: $e');
    }

    // Handle links while app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (err) => print('⚠️ Deep link stream error: $err'),
    );
  }

  void _handleDeepLink(Uri uri) {
    print('🔗 Deep link received: $uri');
    if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(token: token)),
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GetIt.instance<AuthBloc>()),
        BlocProvider(create: (context) => GetIt.instance<GoalBloc>()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // ✅ required for the deep-link push to work
        title: 'Habit Harbor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const AppView(),
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}
