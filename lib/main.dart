import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'application/auth/auth_bloc.dart';
import 'application/auth/auth_event.dart';
import 'application/auth/auth_state.dart';
import 'application/goal/goal_bloc.dart';
import 'core/app/app.dart';
import 'core/injection_container/injection_container.dart';
import 'core/service/notification/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();

    // Initialize all dependencies first
    await initializeDependencies();
    print('✅ Dependencies initialized successfully');

    // Run the app only after everything is properly set up
    runApp(const MyApp());
  } catch (e) {
    print('❌ Failed to initialize app: $e');
    // You might want to show an error screen here
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Failed to start app: $e'))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => GetIt.instance<AuthBloc>()),
          BlocProvider(create: (context) => GetIt.instance<GoalBloc>()),
        ],
        child: const AppInitializer(),
      ),
    );
  }
}

/// Widget that handles initial app state and authentication check
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();

    // Schedule the auth check after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<AuthBloc>().add(CheckAuthStatus());
        } catch (e) {
          print('⚠️ Auth check error: $e');
          // Handle auth check error if needed
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show loading while checking auth status
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show main app once auth state is determined
        return const AppView();
      },
    );
  }
}

/// Alternative simpler version without the initializer widget
/// Use this if you prefer to handle auth state directly in AppView
class MyAppSimple extends StatelessWidget {
  const MyAppSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => GetIt.instance<AuthBloc>()),
          BlocProvider(create: (context) => GetIt.instance<GoalBloc>()),
        ],
        child: const AppView(),
      ),
    );
  }
}
