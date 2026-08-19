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
  static const Color kAccent = Color(0xFF5B3DF5);

  late TabController _tabController;
  String _selectedPeriod = 'month';

  Map<String, dynamic>? _overviewData;
  Map<String, Map<String, dynamic>> _goalAnalytics = {};
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _periodKeys = ['month', 'quarter', 'halfyear', 'year'];
  final List<String> _periodLabels = ['Month', 'Quarter', '6 Months', 'Year'];

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
      final newPeriod = _periodKeys[_tabController.index];
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

  // ── History Edit ────────────────────────────────────────────────────────
  void _onCalendarDayTapped(
    BuildContext context,
    String goalId,
    String dateStr,
    String? currentStatus,
  ) {
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
                                ? null
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

  // ── Helpers ──────────────────────────────────────────────────────────────
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

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FB),
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
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Goals History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: kAccent),
                        onPressed: _loadAnalyticsData,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: kAccent),
                                SizedBox(height: 16),
                                Text('Loading analytics...'),
                              ],
                            ),
                          )
                          : _errorMessage != null
                          ? _buildErrorState()
                          : _overviewData == null
                          ? _buildEmptyState()
                          : _buildContent(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
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
        const SizedBox(height: 16),
        _buildPeriodTabs(),
        const SizedBox(height: 12),
        _buildLegendRow(),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGoalsList(goals),
              _buildGoalsList(goals),
              _buildGoalsList(goals),
              _buildGoalsList(goals),
            ],
          ),
        ),
      ],
    );
  }

  // ── Error / Empty ──────────────────────────────────────────────────────
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
                backgroundColor: kAccent,
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

  // ── Summary Stats: purple gradient overview card ──────────────────────
  Widget _buildSummaryStats() {
    final stats = _overviewData?['stats'] as Map<String, dynamic>?;
    final totalGoals = _safeParseInt(_overviewData?['totalGoals']) ?? 0;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 22),
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
          Expanded(child: _buildStatItem('$totalGoals', 'Total Goals')),
          Expanded(
            child: _buildStatItem(
              '${_safeParseInt(stats['completed']) ?? 0}',
              'Completed',
            ),
          ),
          Expanded(
            child: _buildStatItem(
              '${_safeParseInt(stats['completionRate']) ?? 0}%',
              'Success Rate',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ── Pill-style segmented tabs ──────────────────────────────────────────
  Widget _buildPeriodTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        tabs: _periodLabels.map((l) => Tab(text: l)).toList(),
      ),
    );
  }

  // ── Legend row: colored dots + labels ──────────────────────────────────
  Widget _buildLegendRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _legendDot('Done', const Color(0xFF34C759)),
          _legendDot('Missed', const Color(0xFFFF3B30)),
          _legendDot('Holiday', const Color(0xFF0A84FF)),
          _legendDot('Sick', const Color(0xFFFF9F0A)),
          _legendDot('Skipped', Colors.grey),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  // ── Goals List ───────────────────────────────────────────────────────
  Widget _buildGoalsList(List<Goal> goals) {
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
      color: kAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          return _buildGoalStatsCard(goal, _goalAnalytics[goal.id]);
        },
      ),
    );
  }

  // ── Goal Stats Card matching mockup: header, 4 mini-stat tiles, calendar ──
  Widget _buildGoalStatsCard(Goal goal, Map<String, dynamic>? analytics) {
    Color goalColor = kAccent;
    try {
      goalColor = Color(int.parse(goal.color.replaceFirst('#', '0xff')));
    } catch (_) {}

    if (analytics == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: goalColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getGoalIcon(goal.icon), color: goalColor, size: 22),
            ),
            const SizedBox(width: 14),
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
      );
    }

    final stats = analytics['stats'] as Map<String, dynamic>? ?? {};
    final logs = analytics['logs'] as List<dynamic>? ?? [];

    final completed = _safeParseInt(stats['completed']) ?? 0;
    final missed = _safeParseInt(stats['missed']) ?? 0;
    final currentStreak = _safeParseInt(stats['currentStreak']) ?? 0;
    final longestStreak = _safeParseInt(stats['longestStreak']) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: goalColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getGoalIcon(goal.icon), color: goalColor, size: 22),
          ),
          title: Text(
            goal.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            goal.category,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatTile(
                    '$completed',
                    'Completed',
                    const Color(0xFFDFF5E1),
                    const Color(0xFF34C759),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatTile(
                    '$missed',
                    'Missed',
                    const Color(0xFFFBE2E1),
                    const Color(0xFFFF3B30),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatTile(
                    '$currentStreak',
                    'Current Streak',
                    const Color(0xFFEDE9FE),
                    const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatTile(
                    '$longestStreak',
                    'Best Streak',
                    const Color(0xFFEDE9FE),
                    const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRealCalendar(logs, goalColor, goal.id),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatTile(String value, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: fg.withOpacity(0.8), fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Calendar ─────────────────────────────────────────────────────────
  Widget _buildRealCalendar(
    List<dynamic> logs,
    Color goalColor,
    String goalId,
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
      children:
          monthGroups.entries.map((entry) {
            final monthDates = entry.value;
            final monthLabel = DateFormat('MMMM yyyy').format(monthDates.first);
            return _buildMonthGrid(
              monthLabel,
              monthDates,
              logMap,
              goalColor,
              goalId,
            );
          }).toList(),
    );
  }

  Widget _buildMonthGrid(
    String monthLabel,
    List<DateTime> monthDates,
    Map<String, String> logMap,
    Color goalColor,
    String goalId,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children:
                ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 4),
          ...weeks.map(
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children:
                    week.map((date) {
                      if (date == null) {
                        return const Expanded(child: SizedBox(height: 30));
                      }

                      final dateStr = DateFormat('yyyy-MM-dd').format(date);
                      final status = logMap[dateStr];
                      final isToday = dateStr == todayStr;
                      final isFuture = dateStr.compareTo(todayStr) > 0;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: GestureDetector(
                            onTap:
                                isFuture
                                    ? null
                                    : () => _onCalendarDayTapped(
                                      context,
                                      goalId,
                                      dateStr,
                                      status,
                                    ),
                            child: Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color:
                                    status != null
                                        ? _getColorForStatus(status, goalColor)
                                        : null,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    status == null
                                        ? Border.all(
                                          color:
                                              isToday
                                                  ? kAccent
                                                  : Colors.grey[300]!,
                                          width: isToday ? 1.6 : 1,
                                          style: BorderStyle.solid,
                                        )
                                        : isToday
                                        ? Border.all(color: kAccent, width: 1.6)
                                        : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        status != null
                                            ? Colors.white
                                            : Colors.grey[400],
                                  ),
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

  // ── Helper Methods ───────────────────────────────────────────────────
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
        start = DateTime(now.year, now.month - 2, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'halfyear':
        start = DateTime(now.year, now.month - 5, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'year':
        start = DateTime(now.year, now.month - 11, 1);
        end = DateTime(now.year, now.month + 1, 0);
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
        return Colors.grey[300]!;
    }
  }
}
