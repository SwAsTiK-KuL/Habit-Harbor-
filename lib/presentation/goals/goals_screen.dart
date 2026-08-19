import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../application/goal/goal_bloc.dart';
import '../../application/goal/goal_event.dart';
import '../../application/goal/goal_state.dart';
import '../../domain/entities/goals/goals_log.dart';
import '../../domain/entities/user.dart';
import '../../infrastucture/models/goals/goal.dart';
import 'create_goals_screen.dart';
import 'goals_detail_screen.dart';

class GoalsScreen extends StatefulWidget {
  final User user;
  const GoalsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalBloc>().add(const LoadGoals());
    });
  }

  void _navigateToCreateGoal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(
              value: context.read<GoalBloc>(),
              child: const CreateGoalScreen(),
            ),
      ),
    );
  }

  void _navigateToGoalDetails(BuildContext context, Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(
              value: context.read<GoalBloc>(),
              child: GoalDetailsScreen(goal: goal),
            ),
      ),
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
          context.read<GoalBloc>().add(
            UpdateGoalLogStatus(logId: goal.todayLogId!, status: status.name),
          );
        } else {
          context.read<GoalBloc>().add(
            LogGoalStatus(goalId: goal.id, status: status.name),
          );
        }
      },
    );
  }

  void _deleteGoal(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Goal'),
            content: Text(
              'Are you sure you want to delete "${goal.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<GoalBloc>().add(DeleteGoal(goalId: goal.id));
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _editGoal(BuildContext context, Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(
              value: context.read<GoalBloc>(),
              child: CreateGoalScreen(goalToEdit: goal),
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

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    Color goalColor = Colors.deepPurple;
    try {
      goalColor = Color(int.parse(goal.color.replaceFirst('#', '0xff')));
    } catch (e) {}

    String statusEmoji = '✅';
    String statusText = 'Completed';
    Color statusColor = Colors.green;
    bool isAutoCompleted = true;

    if (goal.todayStatus != null && goal.todayStatus!.isNotEmpty) {
      isAutoCompleted = false;
      try {
        final status = GoalLogStatus.values.firstWhere(
          (s) => s.name == goal.todayStatus,
          orElse: () => GoalLogStatus.completed,
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
      } catch (e) {
        print('⚠️ Error parsing goal status: $e');
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _navigateToGoalDetails(context, goal),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showStatusDialog(context, goal),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            statusEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete')
                        _deleteGoal(context, goal);
                      else if (value == 'edit')
                        _editGoal(context, goal);
                    },
                    itemBuilder:
                        (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatFrequency(goal.targetFrequency, goal.targetCount),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isAutoCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'Auto ✨',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
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

  String _formatFrequency(String frequency, int count) {
    if (count == 1) {
      return frequency[0].toUpperCase() + frequency.substring(1);
    }
    return '$count times $frequency';
  }

  int _getCompletedTodayCount(List<Goal> goals) {
    return goals
        .where((g) => g.todayStatus == null || g.todayStatus == 'completed')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<GoalBloc>().add(const LoadGoals()),
          ),
        ],
      ),
      body: BlocConsumer<GoalBloc, GoalState>(
        listener: (context, state) {
          if (state is GoalError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GoalCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Goal created successfully! 🎉'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is GoalDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Goal deleted successfully'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (state is GoalLogged) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Goal status updated! ✅'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: RefreshIndicator(
              onRefresh:
                  () async => context.read<GoalBloc>().add(const LoadGoals()),
              child: _buildContent(context, state),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateGoal(context),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GoalState state) {
    if (state is GoalLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your goals...'),
          ],
        ),
      );
    } else if (state is GoalError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load goals',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<GoalBloc>().add(const LoadGoals()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (state is GoalsLoaded ||
        state is GoalCreated ||
        state is GoalDeleted ||
        state is GoalLogged ||
        state is GoalActionLoading) {
      List<Goal> goals = [];
      if (state is GoalsLoaded)
        goals = state.goals;
      else if (state is GoalCreated)
        goals = state.allGoals;
      else if (state is GoalDeleted)
        goals = state.goals;
      else if (state is GoalLogged)
        goals = state.allGoals;
      else if (state is GoalActionLoading)
        goals = state.goals;

      if (goals.isEmpty) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'No goals yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create your first goal to start\nbuilding better habits!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateGoal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Goal'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '${goals.length}',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const Text('Total Goals'),
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
                          Text(
                            '${_getCompletedTodayCount(goals)}',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text('Completed Today'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: goals.length,
              itemBuilder:
                  (context, index) => _buildGoalCard(context, goals[index]),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
