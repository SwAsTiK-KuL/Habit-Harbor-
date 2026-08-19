import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  static const Color kAccent = Color(0xFF5B3DF5);
  int _navIndex = 0;

  List<Goal> _cachedGoals = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<GoalBloc>().state;
      final goals = _getGoalsFromState(currentState);
      if (goals.isNotEmpty) {
        setState(() => _cachedGoals = goals);
      }
      context.read<GoalBloc>().add(const LoadGoals());
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

  // ── Redesigned status picker matching mockup: header + 2-row icon grid ──
  void _showStatusDialog(BuildContext context, Goal goal) {
    Color goalColor = kAccent;
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: goalColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getGoalIcon(goal.icon),
                      color: goalColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Log today's status",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: Icon(Icons.close_rounded, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.completed,
                    icon: Icons.check_circle_rounded,
                    label: 'Done',
                    bgColor: const Color(0xFFDFF5E1),
                    fgColor: const Color(0xFF34C759),
                  ),
                  const SizedBox(width: 10),
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.missed,
                    icon: Icons.cancel_rounded,
                    label: 'Missed',
                    bgColor: const Color(0xFFFBE2E1),
                    fgColor: const Color(0xFFFF3B30),
                  ),
                  const SizedBox(width: 10),
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.holiday,
                    icon: Icons.beach_access_rounded,
                    label: 'Holiday',
                    bgColor: const Color(0xFFDCEBFB),
                    fgColor: const Color(0xFF0A84FF),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.sick,
                    icon: Icons.sick_rounded,
                    label: 'Sick',
                    bgColor: const Color(0xFFFCE8D6),
                    fgColor: const Color(0xFFFF9F0A),
                  ),
                  const SizedBox(width: 10),
                  _buildSheetOption(
                    dialogContext: dialogContext,
                    goal: goal,
                    status: GoalLogStatus.skipped,
                    icon: Icons.remove_circle_rounded,
                    label: 'Skipped',
                    bgColor: const Color(0xFFE7E7EA),
                    fgColor: const Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: SizedBox(),
                  ), // empty 3rd slot, matches mockup's 3+2 grid
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required BuildContext dialogContext,
    required Goal goal,
    required GoalLogStatus status,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(dialogContext);
          context.read<GoalBloc>().add(
            LogGoalStatus(goalId: goal.id, status: status.name),
          );
        },
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fgColor, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Goal card ──
  Widget _buildGoalCard(BuildContext context, Goal goal) {
    Color goalColor = kAccent;
    try {
      goalColor = Color(int.parse(goal.color.replaceFirst('#', '0xff')));
    } catch (e) {}

    final List<String?> last7DayStatuses = _getLast7DayStatuses(goal);

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => _showStatusDialog(context, goal),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: goalColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
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
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal.category,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 14),
              _buildSegmentedProgressBar(last7DayStatuses),
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
        statuses.add(goal.recentLogs?[dateStr]);
      }
    }

    return statuses;
  }

  Widget _buildSegmentedProgressBar(List<String?> statuses) {
    final todayIndex = DateTime.now().weekday - 1;
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: List.generate(7, (index) {
        final status = statuses[index];
        final isToday = index == todayIndex;
        final isFuture = index > todayIndex;
        final color = _getStatusColor(status);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                Text(
                  dayLabels[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isToday ? Colors.black87 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color:
                        isFuture
                            ? Colors.grey[200]
                            : status != null
                            ? color
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isToday && status == null
                            ? Border.all(color: kAccent, width: 1.5)
                            : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF34C759);
      case 'missed':
        return const Color(0xFFFF3B30);
      case 'holiday':
        return const Color(0xFF0A84FF);
      case 'sick':
        return const Color(0xFFFF9F0A);
      case 'skipped':
        return Colors.grey;
      default:
        return Colors.grey[200]!;
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
      backgroundColor: const Color(0xFFF5F3FB),
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
              if (goalState is GoalsLoaded) {
                setState(() => _cachedGoals = goalState.goals);
              } else if (goalState is GoalLogged) {
                setState(() => _cachedGoals = goalState.allGoals);
              } else if (goalState is GoalLogUpdated) {
                setState(() => _cachedGoals = goalState.allGoals);
              }

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
                bottom: false,
                child: RefreshIndicator(
                  onRefresh:
                      () async =>
                          context.read<GoalBloc>().add(const LoadGoals()),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildWelcomeCard(context, goalState),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Text(
                              'Your goals',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                'Tap a goal to log today',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildGoalsContent(context, goalState),
                        const SizedBox(height: 24),
                        // ✅ RESTORED — was accidentally dropped last edit
                        _buildQuickStats(context, goalState),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // bottomNavigationBar: _buildBottomNavBar(context),
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
        backgroundColor: kAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.sailing_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Habit Harbor',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _navigateToProfile(context),
          icon: Icon(Icons.account_circle, size: 32, color: kAccent),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context, GoalState goalState) {
    final goals = _cachedGoals;
    // final goals = _getGoalsFromState(goalState);
    final total = goals.length;
    final logged = goals.where((g) => g.todayStatus != null).length;

    final String subtitleText =
        total == 0
            ? 'Add your first goal to get started 🚀'
            : logged == total
            ? "You're all logged for today 🎉"
            : "$logged of $total goals logged today";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B3DF5), Color(0xFF3E2AB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kAccent.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.user.fullName.split(' ').first} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitleText,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.read<GoalBloc>().add(const LoadGoals()),
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsContent(BuildContext context, GoalState goalState) {
    if (goalState is GoalLoading && _cachedGoals.isEmpty)
      return _buildLoadingState();
    if (goalState is GoalError && _cachedGoals.isEmpty) {
      return _buildErrorState(context, goalState.message);
    }
    if (_cachedGoals.isEmpty) return _buildEmptyState(context);
    return Column(
      children:
          _cachedGoals.map((goal) => _buildGoalCard(context, goal)).toList(),
    );
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

  // ✅ RESTORED — quick stats row (History / Total Habits) that was dropped
  Widget _buildQuickStats(BuildContext context, GoalState goalState) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
            child: InkWell(
              onTap: () => _navigateToHistory(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: kAccent, size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'History',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View analytics',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BlocProvider.value(
                          value: context.read<GoalBloc>(),
                          child: AllHabitsScreen(goals: _cachedGoals),
                        ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: kAccent,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    _buildTotalStatsText(goalState),
                    const SizedBox(height: 2),
                    Text(
                      'Total habits',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalStatsText(GoalState goalState) {
    return Text(
      '${_cachedGoals.length}',
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }

  List<Goal> _getGoalsFromState(GoalState goalState) {
    if (goalState is GoalsLoaded) return goalState.goals;
    if (goalState is GoalLogged) return goalState.allGoals;
    if (goalState is GoalLogUpdated) return goalState.allGoals;
    if (goalState is GoalActionLoading) return goalState.goals;
    return [];
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kAccent,
      unselectedItemColor: Colors.grey[500],
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == _navIndex) return;
        if (index == 1) {
          _navigateToHistory(context);
        } else if (index == 2) {
          _navigateToProfile(context);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
