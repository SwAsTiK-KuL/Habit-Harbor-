import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:habit_harbor/presentation/auth/profile_screen.dart';
import 'package:habit_harbor/presentation/auth/total_habits_screen.dart';
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

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<GoalBloc>().state;

      if (currentState is! GoalsLoaded &&
          currentState is! GoalLogged &&
          currentState is! GoalCreated &&
          currentState is! GoalActionLoading) {
        context.read<GoalBloc>().add(const LoadGoals());
      }
    });
  }

  void _showClassicSnackbar(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color iconColor = Colors.green,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
      _showClassicSnackbar(
        context,
        title: 'Unable to Open',
        subtitle: 'Could not open history. Please try again.',
        icon: Icons.history_toggle_off_rounded,
        iconColor: Colors.red,
      );
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user)),
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
    Color goalColor = Colors.blue;
    try {
      goalColor = Color(int.parse(goal.color.replaceFirst('#', '0xff')));
    } catch (e) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: goalColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: goalColor.withOpacity(0.3)),
                    ),
                    child: Icon(
                      _getGoalIcon(goal.icon),
                      color: goalColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How did it go?',
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal.title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.completed,
                    icon: Icons.check_rounded,
                    label: 'Done',
                    color: const Color(0xFF30D158),
                  ),
                  const SizedBox(width: 12),
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.missed,
                    icon: Icons.close_rounded,
                    label: 'Missed',
                    color: const Color(0xFFFF453A),
                  ),
                  const SizedBox(width: 12),
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.holiday,
                    icon: Icons.beach_access_rounded,
                    label: 'Holiday',
                    color: const Color(0xFF0A84FF),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.sick,
                    icon: Icons.healing_rounded,
                    label: 'Sick',
                    color: const Color(0xFFFF9F0A),
                  ),
                  const SizedBox(width: 12),
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.skipped,
                    icon: Icons.skip_next_rounded,
                    label: 'Skipped',
                    color: const Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Container(
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.black38,
                              size: 26,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black38,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

  // ── New tile builder ─────────────────────────────────────────────────────────
  Widget _buildSheetOption({
    required BuildContext dialogContext,
    required Goal goal,
    required GoalLogStatus status,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(dialogContext);
          // ✅ reuse your existing BLoC dispatch here
          context.read<GoalBloc>().add(
            LogGoalStatus(goalId: goal.id, status: status.name),
          );
        },
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
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
    } catch (e) {}

    final List<String?> last7DayStatuses = _getLast7DayStatuses(goal);

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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${goal.category} · Last 7 Days',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    _buildSegmentedProgressBar(last7DayStatuses),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String?> _getLast7DayStatuses(Goal goal) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final List<String?> statuses = [];

    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (date.isAfter(now)) {
        statuses.add(null);
      } else if (dateStr == todayStr) {
        statuses.add(goal.todayStatus ?? goal.recentLogs?[dateStr]);
      } else {
        // Past days → use recentLogs from backend
        statuses.add(goal.recentLogs?[dateStr]);
      }
    }

    return statuses;
  }

  Widget _buildSegmentedProgressBar(List<String?> statuses) {
    final todayIndex = DateTime.now().weekday - 1;
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: List.generate(7, (index) {
        final status = statuses[index];
        final color = _getStatusColor(status);
        final isToday = index == todayIndex;
        final isFuture = index > todayIndex;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                // ── Bar segment ──────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  height: isToday ? 36 : 28,
                  decoration: BoxDecoration(
                    color:
                        isFuture
                            ? Colors.grey[100]
                            : status != null
                            ? color.withOpacity(0.15)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isToday
                              ? color != Colors.grey[300]
                                  ? color.withOpacity(0.6)
                                  : Colors.black26
                              : isFuture
                              ? Colors.grey[200]!
                              : status != null
                              ? color.withOpacity(0.3)
                              : Colors.grey[200]!,
                      width: isToday ? 1.5 : 1,
                    ),
                    boxShadow:
                        isToday && status != null
                            ? [
                              BoxShadow(
                                color: color.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Center(
                    child:
                        isFuture
                            ? Icon(
                              Icons.remove,
                              size: 10,
                              color: Colors.grey[300],
                            )
                            : status != null
                            ? Icon(
                              _getStatusIcon(status),
                              size: isToday ? 16 : 13,
                              color: color,
                            )
                            : Icon(
                              Icons.circle_outlined,
                              size: 10,
                              color: Colors.grey[350],
                            ),
                  ),
                ),
                const SizedBox(height: 5),
                // ── Day label ────────────────────────────
                Text(
                  dayLabels[index],
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isToday ? Colors.black87 : Colors.black38,
                    letterSpacing: 0.2,
                  ),
                ),
                // ── Today dot ────────────────────────────
                const SizedBox(height: 3),
                Container(
                  width: isToday ? 4 : 0,
                  height: isToday ? 4 : 0,
                  decoration: BoxDecoration(
                    color: status != null ? color : Colors.black45,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Icon per status ──────────────────────────────────────
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_rounded;
      case 'missed':
        return Icons.close_rounded;
      case 'holiday':
        return Icons.beach_access_rounded;
      case 'sick':
        return Icons.healing_rounded;
      case 'skipped':
        return Icons.skip_next_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'missed':
        return Colors.red;
      case 'holiday':
        return Colors.blue;
      case 'sick':
        return Colors.orange;
      case 'skipped':
        return Colors.grey;
      default:
        return Colors.grey[300]!;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showClassicSnackbar(
              context,
              title: 'Something went wrong',
              subtitle: state.message,
              icon: Icons.error_outline_rounded,
              iconColor: Colors.red,
            );
          }
        },
        builder: (context, authState) {
          return BlocConsumer<GoalBloc, GoalState>(
            listener: (context, goalState) {
              if (goalState is GoalError) {
                _showClassicSnackbar(
                  context,
                  title: 'Something went wrong',
                  subtitle: goalState.message,
                  icon: Icons.error_outline_rounded,
                  iconColor: Colors.red,
                );
              } else if (goalState is GoalLogged) {
                _showClassicSnackbar(
                  context,
                  title: 'Goal Logged!',
                  subtitle: 'Great job keeping up your habit 🎉',
                  icon: Icons.check_rounded,
                  iconColor: Colors.green,
                );
              } else if (goalState is GoalLogUpdated) {
                _showClassicSnackbar(
                  context,
                  title: 'Goal Updated!',
                  subtitle: 'Your log has been updated ✅',
                  icon: Icons.edit_rounded,
                  iconColor: Colors.blue,
                );
              }
            },
            builder: (context, goalState) {
              return SafeArea(
                child: RefreshIndicator(
                  onRefresh:
                      () async =>
                          context.read<GoalBloc>().add(const LoadGoals()),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        _buildWelcomeCard(context),
                        const SizedBox(height: 32),
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
                        _buildGoalsContent(context, goalState),
                        const SizedBox(height: 24),
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
          final goalBloc = context.read<GoalBloc>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BlocProvider.value(
                    value: goalBloc,
                    child: const CreateGoalScreen(),
                  ),
            ),
          );
        },
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
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
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 30, color: Colors.blue[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${widget.user.fullName.split(' ').first} 👋',
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
            IconButton(
              onPressed: () => context.read<GoalBloc>().add(const LoadGoals()),
              icon: Icon(Icons.refresh, color: Colors.green[600], size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsContent(BuildContext context, GoalState goalState) {
    if (goalState is GoalLoading) return _buildLoadingState();
    if (goalState is GoalError)
      return _buildErrorState(context, goalState.message);

    if (goalState is GoalsLoaded ||
        goalState is GoalLogged ||
        goalState is GoalLogUpdated ||
        goalState is GoalActionLoading) {
      List<Goal> goals = [];
      if (goalState is GoalsLoaded)
        goals = goalState.goals;
      else if (goalState is GoalLogged)
        goals = goalState.allGoals;
      else if (goalState is GoalLogUpdated)
        goals = goalState.allGoals;
      else if (goalState is GoalActionLoading)
        goals = goalState.goals;

      if (goals.isEmpty) return _buildEmptyState(context);
      return Column(
        children: goals.map((goal) => _buildGoalCard(context, goal)).toList(),
      );
    }

    return _buildEmptyState(context);
  }

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator());

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
            child: InkWell(
              onTap: () {
                final goals = _getGoalsFromState(
                  context.read<GoalBloc>().state,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BlocProvider.value(
                          value: context.read<GoalBloc>(),
                          child: AllHabitsScreen(goals: goals),
                        ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.trending_up, color: Colors.green[600], size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Total Habits',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildTotalStatsText(goalState),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Goal> _getGoalsFromState(GoalState goalState) {
    if (goalState is GoalsLoaded) return goalState.goals;
    if (goalState is GoalLogged) return goalState.allGoals;
    if (goalState is GoalLogUpdated) return goalState.allGoals;
    return [];
  }

  Widget _buildTodayStatsText(GoalState goalState) {
    final goals = _getGoalsFromState(goalState);
    if (goals.isEmpty) {
      return const Text(
        'No goals yet',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    final total = goals.length;
    final logged = goals.where((g) => g.todayStatus != null).length;
    final pending = total - logged;
    final hour = DateTime.now().hour;

    final timeHint =
        hour < 12
            ? '☀️ Morning'
            : hour < 18
            ? '🌤 Afternoon'
            : '🌙 Tonight';

    return Text(
      pending == 0 ? 'All logged! ' : '$timeHint · $pending left',
      style: TextStyle(
        color: pending == 0 ? Colors.green : Colors.grey,
        fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTotalStatsText(GoalState goalState) {
    final goals = _getGoalsFromState(goalState);
    if (goals.isEmpty)
      return const Text(
        '- active',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    return Text(
      '${goals.length} active',
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    );
  }
}
