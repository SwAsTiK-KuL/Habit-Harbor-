import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:habit_harbor/presentation/auth/profile_screen.dart';
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

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
    );
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
    Color goalColor = Colors.blue;
    try {
      goalColor = Color(int.parse(goal.color.replaceFirst('#', '0xff')));
    } catch (e) {
      // Default color if parsing fails
    }

    // Calculate streak (mock data for now - you can integrate with real streak logic)
    int currentStreak = _calculateStreak(goal);
    int totalDays = 7; // Weekly view
    double progress = currentStreak / totalDays;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showStatusDialog(context, goal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${goal.category} Streak',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    // Progress Bar
                    _buildProgressBar(currentStreak, totalDays, goalColor),
                  ],
                ),
              ),

              // Progress Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currentStreak / $totalDays days',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
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

  Widget _buildProgressBar(int current, int total, Color color) {
    return Row(
      children: List.generate(total, (index) {
        bool isCompleted = index < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
            height: 8,
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  int _calculateStreak(Goal goal) {
    // Mock calculation - replace with real streak logic
    switch (goal.title.toLowerCase()) {
      case 'morning workout':
        return 4;
      case 'read 20 minutes daily':
        return 2;
      case 'drink water':
        return 5;
      case 'meditate':
        return 6;
      case 'no junk food':
        return 3;
      default:
        return 0;
    }
  }

  IconData _getGoalIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'fitness':
        return Icons.fitness_center;
      case 'book':
        return Icons.menu_book;
      case 'water':
        return Icons.water_drop;
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
        backgroundColor: const Color(0xFFF5F7FB),
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
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _buildHeader(context),
                          const SizedBox(height: 24),

                          // Welcome Card
                          _buildWelcomeCard(context),
                          const SizedBox(height: 32),

                          // Your Goals Section
                          Text(
                            'Your Goals',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Goals List
                          _buildGoalsContent(context, goalState),

                          const SizedBox(height: 24),

                          // Quick Stats Section
                          _buildQuickStats(context, goalState),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            try {
              final goalBloc = context.read<GoalBloc>();
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
            } catch (e) {
              try {
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
              } catch (createError) {
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
          backgroundColor: Colors.blue[600],
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.sailing, size: 32, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Text(
          'Habit Harbor',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _navigateToProfile(context),
          icon: Icon(Icons.account_circle, size: 32, color: Colors.blue[600]),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // User Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 30, color: Colors.blue[700]),
            ),
            const SizedBox(width: 16),

            // Welcome Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${user.fullName.split(' ').first} 👋',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here are your current goals',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

            // Refresh Button
            IconButton(
              onPressed: () {
                context.read<GoalBloc>().add(const LoadGoals());
              },
              icon: Icon(Icons.refresh, color: Colors.green[600], size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsContent(BuildContext context, GoalState goalState) {
    if (goalState is GoalLoading) {
      return _buildLoadingState();
    } else if (goalState is GoalError) {
      return _buildErrorState(context, goalState.message);
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
        return _buildEmptyState(context);
      }

      return Column(
        children: goals.map((goal) => _buildGoalCard(context, goal)).toList(),
      );
    }

    return _buildEmptyState(context);
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load goals',
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No goals yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first goal to start building habits!',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, GoalState goalState) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _navigateToHistory(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.history, color: Colors.blue[600], size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'History',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
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
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(Icons.trending_up, color: Colors.green[600], size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Total Habits',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
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
}
