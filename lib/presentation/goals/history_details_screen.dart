import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../application/goal/goal_bloc.dart';
import '../../application/goal/goal_event.dart';
import '../../application/goal/goal_state.dart';
import '../../infrastucture/models/goals/goal.dart';

class HistoryDetailsScreen extends StatefulWidget {
  const HistoryDetailsScreen({super.key});

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
  bool _isLoading = true;
  String? _errorMessage;

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
          _isLoading = true;
          _errorMessage = null;
        });
        _loadAnalyticsData();
      }
    }
  }

  void _loadAnalyticsData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    context.read<GoalBloc>().add(
      LoadOverviewAnalytics(period: _selectedPeriod),
    );
  }

  void _loadGoalAnalytics(List<Goal> goals) {
    for (final goal in goals) {
      context.read<GoalBloc>().add(
        LoadGoalAnalytics(goalId: goal.id, period: _selectedPeriod),
      );
    }
  }

  // ── History Edit ────────────────────────────────────────────────────────────

  /// Called when the user taps a calendar day cell.
  /// Blocks future dates and shows a bottom sheet to pick a new status.
  void _onCalendarDayTapped(
    BuildContext context,
    String goalId,
    String dateStr,
    String? currentStatus,
  ) {
    // Block future dates
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (dateStr.compareTo(today) > 0) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────
              Row(
                children: [
                  const Icon(Icons.edit_calendar, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Edit  $dateStr',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (currentStatus != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getColorForStatus(currentStatus, Colors.grey),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Current: $currentStatus',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Select new status:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              // ── Status buttons ────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    ['completed', 'missed', 'holiday', 'sick', 'skipped'].map((
                      status,
                    ) {
                      final isCurrentStatus = status == currentStatus;
                      return ElevatedButton.icon(
                        onPressed:
                            isCurrentStatus
                                ? null // already this status — no-op
                                : () {
                                  Navigator.pop(ctx);
                                  context.read<GoalBloc>().add(
                                    EditHistoryLog(
                                      goalId: goalId,
                                      date: dateStr,
                                      status: status,
                                    ),
                                  );
                                },
                        icon: Icon(_getStatusIcon(status), size: 14),
                        label: Text(
                          status,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCurrentStatus
                                  ? Colors.grey[300]
                                  : _getColorForStatus(status, Colors.grey),
                          foregroundColor:
                              isCurrentStatus ? Colors.grey[600] : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'missed':
        return Icons.cancel_outlined;
      case 'holiday':
        return Icons.beach_access_outlined;
      case 'sick':
        return Icons.sick_outlined;
      case 'skipped':
        return Icons.skip_next_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Goal? _goalFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return Goal(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        category: json['category']?.toString() ?? 'General',
        color: json['color']?.toString() ?? '#4CAF50',
        icon: json['icon']?.toString() ?? 'star',
        targetFrequency: json['target_frequency']?.toString() ?? 'daily',
        targetCount: _safeParseInt(json['target_count']) ?? 1,
        isActive: json['is_active'] == true,
        createdAt: _safeParseDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _safeParseDateTime(json['updated_at']) ?? DateTime.now(),
        todayStatus: json['todayStatus']?.toString(),
        todayLogId: json['todayLogId']?.toString(),
      );
    } catch (e) {
      print('Error parsing goal from JSON: $e');
      return null;
    }
  }

  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _safeParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

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
            if (state.period != _selectedPeriod) return;
            setState(() {
              _overviewData = state.data;
              _isLoading = false;
              _errorMessage = null;
            });
            final goalsData = _overviewData?['goals'] as List<dynamic>?;
            if (goalsData != null) {
              final goals =
                  goalsData
                      .map((g) => _goalFromJson(g as Map<String, dynamic>?))
                      .where((g) => g != null)
                      .cast<Goal>()
                      .toList();
              _loadGoalAnalytics(goals);
            }
          } else if (state is GoalAnalyticsLoaded) {
            if (state.period != _selectedPeriod) return;
            setState(() {
              _goalAnalytics[state.goalId] = state.data;
            });
          } else if (state is HistoryLogEdited) {
            context.read<GoalBloc>().add(
              LoadGoalAnalytics(goalId: state.goalId, period: _selectedPeriod),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${state.date} updated to ${state.status}'),
                backgroundColor: _getColorForStatus(state.status, Colors.grey),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is AnalyticsError) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.message;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _loadAnalyticsData,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics...'),
                ],
              ),
            );
          }

          if (_errorMessage != null) return _buildErrorState();
          if (_overviewData == null) return _buildEmptyState();

          final goalsData = _overviewData!['goals'] as List<dynamic>?;
          if (goalsData == null) return _buildEmptyState();

          final goals =
              goalsData
                  .map((g) => _goalFromJson(g as Map<String, dynamic>?))
                  .where((g) => g != null)
                  .cast<Goal>()
                  .toList();

          return Column(
            children: [
              _buildSummaryStats(),
              _buildPeriodTabs(),
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

  // ── Error / Empty ────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error Loading History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnalyticsData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Summary Stats ────────────────────────────────────────────────────────────

  Widget _buildSummaryStats() {
    final stats = _overviewData?['stats'] as Map<String, dynamic>?;
    final totalGoals = _safeParseInt(_overviewData?['totalGoals']) ?? 0;
    if (stats == null) return const SizedBox.shrink();

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
              const Icon(Icons.analytics, color: Colors.white, size: 28),
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
                  '${_safeParseInt(stats['completed']) ?? 0}',
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Success Rate',
                  '${_safeParseInt(stats['completionRate']) ?? 0}%',
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Period Tabs ──────────────────────────────────────────────────────────────

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

  // ── Goals List ───────────────────────────────────────────────────────────────

  Widget _buildGoalsList(List<Goal> goals, String period) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Goals for This Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create some goals to see your progress history',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAnalyticsData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          return _buildGoalStatsCard(goal, _goalAnalytics[goal.id]);
        },
      ),
    );
  }

  // ── Goal Stats Card ──────────────────────────────────────────────────────────

  Widget _buildGoalStatsCard(Goal goal, Map<String, dynamic>? analytics) {
    Color goalColor = Colors.deepPurple;
    try {
      goalColor = Color(int.parse(goal.color.replaceFirst('#', '0xff')));
    } catch (_) {}

    // Loading skeleton while per-goal analytics arrive
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

    final completed = _safeParseInt(stats['completed']) ?? 0;
    final totalDays = _safeParseInt(stats['totalDays']) ?? 1;
    final completionRate = _safeParseInt(stats['completionRate']) ?? 0;
    final currentStreak = _safeParseInt(stats['currentStreak']) ?? 0;
    final longestStreak = _safeParseInt(stats['longestStreak']) ?? 0;

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
              '$completed/$totalDays days tracked ($completionRate%)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Goal started ${DateFormat('MMM d, y').format(goal.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
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
                        '${_safeParseInt(stats['missed']) ?? 0}',
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

                const Text(
                  'Status Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildRealStatusBreakdown(stats),
                const SizedBox(height: 16),

                // ✅ "Tap a day to edit" hint
                Row(
                  children: [
                    const Text(
                      'Calendar View',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(tap a day to edit)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ✅ goalId is now passed down so taps can fire EditHistoryLog
                _buildRealCalendar(logs, goalColor, goal.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Breakdown ─────────────────────────────────────────────────────────

  Widget _buildRealStatusBreakdown(Map<String, dynamic> stats) {
    final statuses = [
      {
        'name': 'Completed',
        'value': _safeParseInt(stats['completed']) ?? 0,
        'color': Colors.green,
        'emoji': '✅',
      },
      {
        'name': 'Missed',
        'value': _safeParseInt(stats['missed']) ?? 0,
        'color': Colors.red,
        'emoji': '❌',
      },
      {
        'name': 'Holiday',
        'value': _safeParseInt(stats['holiday']) ?? 0,
        'color': Colors.blue,
        'emoji': '🏖️',
      },
      {
        'name': 'Sick',
        'value': _safeParseInt(stats['sick']) ?? 0,
        'color': Colors.orange,
        'emoji': '🤒',
      },
      {
        'name': 'Skipped',
        'value': _safeParseInt(stats['skipped']) ?? 0,
        'color': Colors.grey,
        'emoji': '⏭️',
      },
      {
        'name': 'Unlogged',
        'value': _safeParseInt(stats['unloggedDays']) ?? 0,
        'color': Colors.grey[400]!,
        'emoji': '⭕',
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          statuses.map((status) {
            final value = status['value'] as int;
            if (value == 0) return const SizedBox.shrink();
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
                    '${status['name']}: $value',
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

  // ── Calendar ─────────────────────────────────────────────────────────────────

  /// ✅ Accepts [goalId] so each cell can trigger an edit.
  Widget _buildRealCalendar(
    List<dynamic> logs,
    Color goalColor,
    String goalId, // ← NEW
  ) {
    final Map<String, String> logMap = {};
    for (final log in logs) {
      if (log is Map<String, dynamic>) {
        final date = log['date']?.toString();
        final status = log['status']?.toString();
        if (date != null && status != null) logMap[date] = status;
      }
    }

    final dates = _getDateRangeForPeriod(_selectedPeriod);
    if (dates.isEmpty) return const SizedBox.shrink();

    final Map<String, List<DateTime>> monthGroups = {};
    for (final date in dates) {
      final key = DateFormat('yyyy-MM').format(date);
      monthGroups.putIfAbsent(key, () => []).add(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...monthGroups.entries.map((entry) {
          final monthDates = entry.value;
          final monthLabel = DateFormat('MMMM yyyy').format(monthDates.first);
          return _buildMonthGrid(
            monthLabel,
            monthDates,
            logMap,
            goalColor,
            goalId, // ← NEW
          );
        }),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildLegendItem('Completed', Colors.green),
            _buildLegendItem('Missed', Colors.red),
            _buildLegendItem('Holiday', Colors.blue),
            _buildLegendItem('Sick', Colors.orange),
            _buildLegendItem('Skipped', Colors.grey),
            _buildLegendItem('No log', Colors.grey[300]!),
          ],
        ),
      ],
    );
  }

  /// ✅ Accepts [goalId] and wraps each day cell in a GestureDetector.
  Widget _buildMonthGrid(
    String monthLabel,
    List<DateTime> monthDates,
    Map<String, String> logMap,
    Color goalColor,
    String goalId, // ← NEW
  ) {
    final firstDay = monthDates.first;
    final startPadding = (firstDay.weekday - 1) % 7;

    final List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(
      startPadding,
      null,
      growable: true,
    );

    for (final date in monthDates) {
      currentWeek.add(date);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) currentWeek.add(null);
      weeks.add(currentWeek);
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header
          Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Day-of-week headers
          Row(
            children:
                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 4),

          // Week rows
          ...weeks.map(
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children:
                    week.map((date) {
                      // Empty padding cell
                      if (date == null) {
                        return const Expanded(child: SizedBox(height: 28));
                      }

                      final dateStr = DateFormat('yyyy-MM-dd').format(date);
                      final status = logMap[dateStr];
                      final isToday = dateStr == todayStr;
                      final isFuture = dateStr.compareTo(todayStr) > 0;

                      return Expanded(
                        // ✅ GestureDetector wraps the cell
                        child: GestureDetector(
                          onTap:
                              isFuture
                                  ? null // silently ignore future taps
                                  : () => _onCalendarDayTapped(
                                    context,
                                    goalId,
                                    dateStr,
                                    status,
                                  ),
                          child: Container(
                            height: 28,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: _getColorForStatus(status, goalColor),
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  isToday
                                      ? Border.all(
                                        color: Colors.black54,
                                        width: 1.5,
                                      )
                                      : null,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      status != null
                                          ? Colors.white
                                          : Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Misc Widgets ─────────────────────────────────────────────────────────────

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = totalWidth * progress.clamp(0.0, 1.0);
        return Stack(
          children: [
            Container(
              height: 6,
              width: totalWidth,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Container(
              height: 6,
              width: filledWidth,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        );
      },
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

  // ── Helper Methods ───────────────────────────────────────────────────────────

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
    DateTime start;
    DateTime end;

    switch (period) {
      case 'month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'quarter':
        start = DateTime(
          now.year,
          now.month - 2,
          1,
        ); // 3 months total, including current
        end = DateTime(now.year, now.month + 1, 0); // end of current month
        break;
      case 'halfyear':
        start = DateTime(now.year, now.month - 5, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        end = now;
        break;
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
    }

    final daysDiff = end.difference(start).inDays + 1;
    return List.generate(daysDiff, (i) => start.add(Duration(days: i)));
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
