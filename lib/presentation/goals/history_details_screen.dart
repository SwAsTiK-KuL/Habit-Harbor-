import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../application/goal/goal_bloc.dart';
import '../../application/goal/goal_event.dart';
import '../../application/goal/goal_state.dart';
import '../../domain/entities/goals/goals_log.dart';
import '../../infrastucture/models/goals/goal.dart';

class HistoryDetailsScreen extends StatefulWidget {
  const HistoryDetailsScreen({Key? key}) : super(key: key);

  @override
  State<HistoryDetailsScreen> createState() => _HistoryDetailsScreenState();
}

class _HistoryDetailsScreenState extends State<HistoryDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';

  // Store analytics data from BLoC
  Map<String, dynamic>? _overviewData;
  Map<String, Map<String, dynamic>> _goalAnalytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final periods = ['month', 'quarter', 'halfyear', 'year'];
      final newPeriod = periods[_tabController.index];
      if (newPeriod != _selectedPeriod) {
        setState(() {
          _selectedPeriod = newPeriod;
          _overviewData = null;
          _goalAnalytics.clear();
        });
        _loadAnalyticsData();
      }
    }
  }

  void _loadAnalyticsData() {
    // Load overview analytics using BLoC
    context.read<GoalBloc>().add(
      LoadOverviewAnalytics(period: _selectedPeriod),
    );
  }

  void _loadGoalAnalytics(List<Goal> goals) {
    // Load individual goal analytics for each goal
    for (final goal in goals) {
      context.read<GoalBloc>().add(
        LoadGoalAnalytics(goalId: goal.id, period: _selectedPeriod),
      );
    }
  }

  // Helper method to convert JSON to Goal using your existing structure
  Goal _goalFromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      color: json['color'] as String? ?? '#4CAF50',
      icon: json['icon'] as String? ?? 'star',
      targetFrequency: json['target_frequency'] as String? ?? 'daily',
      targetCount: json['target_count'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      todayStatus: json['todayStatus'] as String?,
      todayLogId: json['todayLogId'] as String?,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: BlocConsumer<GoalBloc, GoalState>(
        listener: (context, state) {
          if (state is OverviewAnalyticsLoaded) {
            setState(() {
              _overviewData = state.data;
            });

            // Extract goals and load their individual analytics
            final goals =
                (_overviewData!['goals'] as List<dynamic>)
                    .map((g) => _goalFromJson(g))
                    .toList();
            _loadGoalAnalytics(goals);
          } else if (state is GoalAnalyticsLoaded) {
            setState(() {
              _goalAnalytics[state.goalId] = state.data;
            });
          } else if (state is AnalyticsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AnalyticsLoading && _overviewData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_overviewData == null) {
            return _buildEmptyState();
          }

          final goals =
              (_overviewData!['goals'] as List<dynamic>)
                  .map((g) => _goalFromJson(g))
                  .toList();

          return Column(
            children: [
              // Summary Stats Card
              _buildSummaryStats(),

              // Period Tabs
              _buildPeriodTabs(),

              // Goals List with Real Stats
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGoalsList(goals, 'month'),
                    _buildGoalsList(goals, 'quarter'),
                    _buildGoalsList(goals, 'halfyear'),
                    _buildGoalsList(goals, 'year'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryStats() {
    final stats = _overviewData!['stats'] as Map<String, dynamic>;
    final totalGoals = _overviewData!['totalGoals'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[400]!, Colors.deepPurple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                '${_getPeriodDisplayName(_selectedPeriod)} Overview',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Goals', '$totalGoals', Icons.flag),
              ),
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  '${stats['completed']}',
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Success Rate',
                  '${stats['completionRate']}%',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.deepPurple,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.deepPurple,
        tabs: const [
          Tab(text: 'Month'),
          Tab(text: 'Quarter'),
          Tab(text: '6 Months'),
          Tab(text: 'Year'),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goals, String period) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadAnalyticsData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          final analytics = _goalAnalytics[goal.id];
          return _buildGoalStatsCard(goal, analytics);
        },
      ),
    );
  }

  Widget _buildGoalStatsCard(Goal goal, Map<String, dynamic>? analytics) {
    Color goalColor = Colors.deepPurple;
    try {
      goalColor = Color(int.parse(goal.color.replaceFirst('#', '0xff')));
    } catch (e) {
      // Default color if parsing fails
    }

    // Extract real stats from server data or show loading
    if (analytics == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
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
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
    }

    final stats = analytics['stats'] as Map<String, dynamic>? ?? {};
    final logs = analytics['logs'] as List<dynamic>? ?? [];

    final completed = stats['completed'] ?? 0;
    final totalDays = stats['totalDays'] ?? 1;
    final completionRate = stats['completionRate'] ?? 0;
    final currentStreak = stats['currentStreak'] ?? 0;
    final longestStreak = stats['longestStreak'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: goalColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getGoalIcon(goal.icon), color: goalColor, size: 24),
        ),
        title: Text(
          goal.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              goal.category,
              style: TextStyle(
                color: goalColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildProgressBar(completionRate / 100, goalColor),
            const SizedBox(height: 4),
            Text(
              '$completed/$totalDays days ($completionRate%)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        'Completed',
                        '$completed',
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Missed',
                        '${stats['missed'] ?? 0}',
                        Colors.red,
                        Icons.cancel,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Current Streak',
                        '$currentStreak',
                        Colors.orange,
                        Icons.local_fire_department,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Best Streak',
                        '$longestStreak',
                        Colors.purple,
                        Icons.emoji_events,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Real Status Breakdown
                const Text(
                  'Status Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildRealStatusBreakdown(stats),

                const SizedBox(height: 16),

                // Real Calendar View
                const Text(
                  'Calendar View',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildRealCalendar(logs, goalColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealStatusBreakdown(Map<String, dynamic> stats) {
    final statuses = [
      {
        'name': 'Completed',
        'value': stats['completed'] ?? 0,
        'color': Colors.green,
        'emoji': '✅',
      },
      {
        'name': 'Missed',
        'value': stats['missed'] ?? 0,
        'color': Colors.red,
        'emoji': '❌',
      },
      {
        'name': 'Holiday',
        'value': stats['holiday'] ?? 0,
        'color': Colors.blue,
        'emoji': '🏖️',
      },
      {
        'name': 'Sick',
        'value': stats['sick'] ?? 0,
        'color': Colors.orange,
        'emoji': '🤒',
      },
      {
        'name': 'Skipped',
        'value': stats['skipped'] ?? 0,
        'color': Colors.grey,
        'emoji': '⏭️',
      },
      {
        'name': 'Unlogged',
        'value': stats['unloggedDays'] ?? 0,
        'color': Colors.grey[400]!,
        'emoji': '⭕',
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          statuses.map((status) {
            if (status['value'] == 0) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (status['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status['emoji'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${status['name']}: ${status['value']}',
                    style: TextStyle(
                      color: status['color'] as Color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildRealCalendar(List<dynamic> logs, Color goalColor) {
    // Convert logs to date-status map
    final Map<String, String> logMap = {};
    for (final log in logs) {
      logMap[log['date']] = log['status'];
    }

    final dates = _getDateRangeForPeriod(_selectedPeriod);
    final daysInGrid = dates.length > 31 ? 42 : 35;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: daysInGrid,
        itemBuilder: (context, index) {
          if (index < dates.length) {
            final date = dates[index];
            final dateStr = DateFormat('yyyy-MM-dd').format(date);
            final status = logMap[dateStr];

            return Container(
              decoration: BoxDecoration(
                color: _getColorForStatus(status, goalColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: status != null ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Goals History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking goals to see your progress history',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Helper Methods
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

  String _getPeriodDisplayName(String period) {
    switch (period) {
      case 'month':
        return 'This Month';
      case 'quarter':
        return 'This Quarter';
      case 'halfyear':
        return 'Last 6 Months';
      case 'year':
        return 'This Year';
      default:
        return 'This Month';
    }
  }

  List<DateTime> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return List.generate(
          endOfMonth.day,
          (index) => startOfMonth.add(Duration(days: index)),
        );
      case 'quarter':
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startOfQuarter = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        final endOfQuarter = DateTime(now.year, quarter * 3 + 1, 0);
        final daysDiff = endOfQuarter.difference(startOfQuarter).inDays + 1;
        return List.generate(
          daysDiff,
          (index) => startOfQuarter.add(Duration(days: index)),
        );
      case 'halfyear':
        final startOfHalfYear = DateTime(now.year, now.month - 5, 1);
        final daysDiff = today.difference(startOfHalfYear).inDays + 1;
        return List.generate(
          daysDiff,
          (index) => startOfHalfYear.add(Duration(days: index)),
        );
      case 'year':
        final startOfYear = DateTime(now.year, 1, 1);
        final daysDiff = today.difference(startOfYear).inDays + 1;
        return List.generate(
          daysDiff,
          (index) => startOfYear.add(Duration(days: index)),
        );
      default:
        return [];
    }
  }

  Color _getColorForStatus(String? status, Color goalColor) {
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
}
