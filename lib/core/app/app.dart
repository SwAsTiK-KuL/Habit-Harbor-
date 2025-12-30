import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/auth/auth_bloc.dart';
import '../../application/auth/auth_state.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/widgets/bottom_navbar.dart';

class AppView extends StatelessWidget {
  const AppView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show loading spinner during authentication checks
        if (state is AuthLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Habit Harbor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        // Show main screen with bottom navigation for authenticated users
        else if (state is AuthAuthenticated) {
          return BottomNavbar(user: state.user);
        }
        // Show login screen for unauthenticated users (AuthUnauthenticated, AuthError, AuthInitial)
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
