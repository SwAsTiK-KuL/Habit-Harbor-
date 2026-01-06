import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../application/auth/auth_bloc.dart';
import '../../application/auth/auth_event.dart';
import '../../application/auth/auth_state.dart';
import '../../application/goal/goal_bloc.dart';
import '../../application/goal/goal_event.dart';
import '../../application/goal/goal_state.dart';
import '../../domain/entities/goals/goals_log.dart';
import '../../domain/entities/user.dart';
import '../../infrastucture/models/goals/goal.dart';
import '../goals/create_goals_screen.dart';
import '../goals/history_details_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  void _navigateToHistory(BuildContext context) {
    try {
      final goalBloc = context.read<GoalBloc>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => BlocProvider.value(
                value: goalBloc,
                child: const HistoryDetailsScreen(),
              ),
        ),
      );
    } catch (e) {
      print('❌ Error navigating to history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open history. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

  void _markGoalStatus(BuildContext context, String goalId, String status) {
    context.read<GoalBloc>().add(LogGoalStatus(goalId: goalId, status: status));
  }

  void _updateGoalStatus(BuildContext context, String logId, String status) {
    context.read<GoalBloc>().add(
      UpdateGoalLogStatus(logId: logId, status: status),
    );
  }

  void _showStatusDialog(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Update ${goal.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusOption(
                  context: context,
                  dialogContext: dialogContext,
                  goal: goal,
                  status: GoalLogStatus.completed,
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _buildStatusOption(
                  context: context,
                  dialogContext: dialogContext,
                  goal: goal,
                  status: GoalLogStatus.missed,
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
                _buildStatusOption(
                  context: context,
                  dialogContext: dialogContext,
                  goal: goal,
                  status: GoalLogStatus.holiday,
                  icon: Icons.beach_access,
                  color: Colors.blue,
                ),
                _buildStatusOption(
                  context: context,
                  dialogContext: dialogContext,
                  goal: goal,
                  status: GoalLogStatus.sick,
                  icon: Icons.sick,
                  color: Colors.orange,
                ),
                _buildStatusOption(
                  context: context,
                  dialogContext: dialogContext,
                  goal: goal,
                  status: GoalLogStatus.skipped,
                  icon: Icons.skip_next,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStatusOption({
    required BuildContext context,
    required BuildContext dialogContext,
    required Goal goal,
    required GoalLogStatus status,
    required IconData icon,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Row(
        children: [
          Text(status.displayName),
          const SizedBox(width: 8),
          Text(status.emoji, style: const TextStyle(fontSize: 16)),
        ],
      ),
      onTap: () {
        Navigator.pop(dialogContext);
        if (goal.todayLogId != null) {
          _updateGoalStatus(context, goal.todayLogId!, status.name);
        } else {
          _markGoalStatus(context, goal.id, status.name);
        }
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    Color goalColor = Colors.deepPurple;
    try {
      goalColor = Color(int.parse(goal.color.replaceFirst('#', '0xff')));
    } catch (e) {
      // Default color if parsing fails
    }

    String statusEmoji = '⭕';
    String statusText = 'Pending';
    Color statusColor = Colors.grey[600]!;

    if (goal.todayStatus != null) {
      final status = GoalLogStatus.values.firstWhere(
        (s) => s.name == goal.todayStatus,
        orElse: () => GoalLogStatus.missed,
      );
      statusEmoji = status.emoji;
      statusText = status.displayName;

      switch (status) {
        case GoalLogStatus.completed:
          statusColor = Colors.green;
          break;
        case GoalLogStatus.missed:
          statusColor = Colors.red;
          break;
        case GoalLogStatus.holiday:
          statusColor = Colors.blue;
          break;
        case GoalLogStatus.sick:
          statusColor = Colors.orange;
          break;
        case GoalLogStatus.skipped:
          statusColor = Colors.grey;
          break;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: () => _showStatusDialog(context, goal),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Goal Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: goalColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getGoalIcon(goal.icon),
                  color: goalColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Goal Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (goal.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        goal.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: goalColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        goal.category,
                        style: TextStyle(
                          color: goalColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status
              Column(
                children: [
                  Text(statusEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGoalIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'fitness':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'water':
        return Icons.local_drink;
      case 'meditation':
        return Icons.self_improvement;
      case 'work':
        return Icons.work;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'hobby':
        return Icons.palette;
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<GoalBloc>()..add(const LoadGoals()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Habit Harbor'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<GoalBloc>().add(const LoadGoals());
              },
            ),
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
          builder: (context, authState) {
            return BlocConsumer<GoalBloc, GoalState>(
              listener: (context, goalState) {
                if (goalState is GoalError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(goalState.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (goalState is GoalLogged) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal logged successfully! 🎉'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (goalState is GoalLogUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal updated successfully! ✅'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              builder: (context, goalState) {
                return SafeArea(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<GoalBloc>().add(const LoadGoals());
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Welcome Section
                          _buildWelcomeCard(context),
                          const SizedBox(height: 24),

                          // Today's Habits Section
                          _buildSectionHeader(context, goalState),
                          const SizedBox(height: 12),

                          // Goals List or Loading/Error States
                          _buildGoalsContent(context, goalState),

                          const SizedBox(height: 24),

                          // Quick Stats Section
                          _buildQuickStats(context, goalState),

                          const SizedBox(height: 16),

                          // Help Text
                          _buildHelpCard(context),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        // In your GoalsScreen or wherever you navigate from, replace your FloatingActionButton with:
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            try {
              // Try to get the existing GoalBloc
              final goalBloc = context.read<GoalBloc>();

              // Navigate with the existing GoalBloc
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BlocProvider<GoalBloc>.value(
                        value: goalBloc,
                        child: const CreateGoalScreen(),
                      ),
                ),
              );
              print('✅ Navigated with existing GoalBloc');
            } catch (e) {
              print('⚠️ GoalBloc not found in current context: $e');

              try {
                // Create a new GoalBloc instance
                final goalBloc = GetIt.instance<GoalBloc>();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BlocProvider<GoalBloc>(
                          create: (_) => goalBloc,
                          child: const CreateGoalScreen(),
                        ),
                  ),
                );
                print('✅ Navigated with new GoalBloc instance');
              } catch (createError) {
                print('❌ Failed to create GoalBloc: $createError');

                // Show error to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Goal creation is not available: $createError',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Icon(Icons.add),
          tooltip: 'Add New Goal',
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.waves, size: 60, color: Colors.deepPurple[600]),
            const SizedBox(height: 16),
            Text(
              'Welcome back, ${user.fullName.split(' ').first}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Track your daily habits and build consistency',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, GoalState goalState) {
    return Row(
      children: [
        Icon(Icons.today, color: Colors.deepPurple[600], size: 28),
        const SizedBox(width: 8),
        Text(
          "Today's Habits",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
        ),
        const Spacer(),
        if (goalState is GoalLoading || goalState is GoalActionLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildGoalsContent(BuildContext context, GoalState goalState) {
    if (goalState is GoalLoading) {
      return _buildLoadingCard(context);
    } else if (goalState is GoalError) {
      return _buildErrorCard(context, goalState.message);
    } else if (goalState is GoalsLoaded ||
        goalState is GoalLogged ||
        goalState is GoalLogUpdated ||
        goalState is GoalActionLoading) {
      List<Goal> goals = [];
      if (goalState is GoalsLoaded) {
        goals = goalState.goals;
      } else if (goalState is GoalLogged) {
        goals = goalState.allGoals;
      } else if (goalState is GoalLogUpdated) {
        goals = goalState.allGoals;
      } else if (goalState is GoalActionLoading) {
        goals = goalState.goals;
      }

      if (goals.isEmpty) {
        return _buildEmptyStateCard(context);
      }

      return Column(
        children: goals.map((goal) => _buildGoalCard(context, goal)).toList(),
      );
    }

    return _buildEmptyStateCard(context);
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading your habits...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load habits',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<GoalBloc>().add(const LoadGoals());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first habit to start building consistency!',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, GoalState goalState) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: InkWell(
              onTap: () => _navigateToHistory(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.history, color: Colors.blue[600], size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'History',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _buildTodayStatsText(goalState),
                  ],
                ),
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
                  Icon(Icons.trending_up, color: Colors.green[600], size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Total Habits',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  _buildTotalStatsText(goalState),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatsText(GoalState goalState) {
    if (goalState is GoalsLoaded ||
        goalState is GoalLogged ||
        goalState is GoalLogUpdated) {
      List<Goal> goals = [];
      if (goalState is GoalsLoaded) {
        goals = goalState.goals;
      } else if (goalState is GoalLogged) {
        goals = goalState.allGoals;
      } else if (goalState is GoalLogUpdated) {
        goals = goalState.allGoals;
      }

      final completedToday =
          goals.where((goal) => goal.todayStatus == 'completed').length;
      return Text(
        '$completedToday completed',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
    }
    return const Text(
      '- habits',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
  }

  Widget _buildTotalStatsText(GoalState goalState) {
    if (goalState is GoalsLoaded ||
        goalState is GoalLogged ||
        goalState is GoalLogUpdated) {
      List<Goal> goals = [];
      if (goalState is GoalsLoaded) {
        goals = goalState.goals;
      } else if (goalState is GoalLogged) {
        goals = goalState.allGoals;
      } else if (goalState is GoalLogUpdated) {
        goals = goalState.allGoals;
      }

      return Text(
        '${goals.length} active',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
    }
    return const Text(
      '- active',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
  }

  Widget _buildHelpCard(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap any habit to log your progress for today. Use the Goals tab to create and manage habits.',
                style: TextStyle(color: Colors.blue[800], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
