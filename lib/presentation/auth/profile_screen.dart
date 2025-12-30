import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/auth/auth_bloc.dart';
import '../../application/auth/auth_event.dart';
import '../../application/auth/auth_state.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/user_profile_card.dart';
import '../../domain/entities/user.dart';

class ProfileScreen extends StatelessWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

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

  void _handleRefreshProfile(BuildContext context) {
    context.read<AuthBloc>().add(GetProfileRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _handleRefreshProfile(context),
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
          final currentUser = state is AuthAuthenticated ? state.user : user;
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Header
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue[100],
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your Profile',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentUser.fullName,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isLoading) ...[
                            const SizedBox(height: 16),
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Profile Information
                  UserProfileCard(user: currentUser),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _QuickActionTile(
                            icon: Icons.account_circle_outlined,
                            title: 'Update Profile',
                            subtitle: 'Manage your account information',
                            onTap: () => _handleRefreshProfile(context),
                          ),
                          const Divider(),
                          _QuickActionTile(
                            icon: Icons.security_outlined,
                            title: 'Security Settings',
                            subtitle: 'Change password and security options',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Feature coming soon!'),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          _QuickActionTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: 'Manage your notification preferences',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Feature coming soon!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  CustomButton(
                    text: 'Logout',
                    onPressed: () => _handleLogout(context),
                    backgroundColor: Colors.red,
                    isLoading: isLoading,
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

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[600]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
