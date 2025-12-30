import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/auth/auth_bloc.dart';
import '../../application/auth/auth_event.dart';
import '../../application/auth/auth_state.dart';
import '../../domain/entities/user.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<AuthBloc>().add(LogoutRequested());
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Harbor'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.waves,
                            size: 80,
                            color: Colors.deepPurple[600],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'This is HomeScreen',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to Habit Harbor, ${user.fullName}!',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your journey to better habits starts here.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                          if (isLoading) ...[
                            const SizedBox(height: 24),
                            const CircularProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick Stats Section
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.today,
                                  color: Colors.blue[600],
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Today',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const Text(
                                  '0 habits',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: Colors.green[600],
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Streak',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const Text(
                                  '0 days',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
