import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/goal/goal_bloc.dart';
import '../../application/goal/goal_event.dart';
import '../../application/goal/goal_state.dart';
import '../../domain/entities/goals/goals_stats.dart';
import '../../infrastucture/models/goals/goal.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailsScreen({Key? key, required this.goal}) : super(key: key);

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  static const Color kAccent = Color(0xFF5B3DF5);
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    context.read<GoalBloc>().add(
      LoadGoalStats(goalId: widget.goal.id, days: _selectedDays),
    );
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

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
    } catch (e) {
      return kAccent;
    }
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

  Widget _flatCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildStatsCard(BuildContext context, GoalStats stats) {
    return _flatCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedDays,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: kAccent,
                      size: 18,
                    ),
                    style: TextStyle(
                      color: kAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                      DropdownMenuItem(value: 90, child: Text('90 days')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDays = value!;
                      });
                      _loadStats();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Completion Rate / Current Streak
          Row(
            children: [
              Expanded(
                child: _buildHighlightTile(
                  '${stats.completionRate}%',
                  'Completion Rate',
                  const Color(0xFFDFF5E1),
                  const Color(0xFF34C759),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHighlightTile(
                  '${stats.currentStreak}',
                  'Current Streak',
                  const Color(0xFFFCE8D6),
                  const Color(0xFFFF9F0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Detailed Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  stats.completed,
                  const Color(0xFF34C759),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Missed',
                  stats.missed,
                  const Color(0xFFFF3B30),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Holiday',
                  stats.holiday,
                  const Color(0xFF0A84FF),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Sick',
                  stats.sick,
                  const Color(0xFFFF9F0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Longest Streak
          _buildHighlightTile(
            '${stats.longestStreak}',
            'Longest Streak',
            const Color(0xFFEDE9FE),
            const Color(0xFF7C3AED),
            large: true,
            subLabel: 'days in a row',
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightTile(
    String value,
    String label,
    Color bg,
    Color fg, {
    bool large = false,
    String? subLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: large ? 18 : 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 30 : 22,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: fg.withOpacity(0.85),
            ),
          ),
          if (subLabel != null)
            Text(
              subLabel,
              style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalColor = _getColorFromHex(widget.goal.color);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3FB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.goal.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _showClassicSnackbar(
                  context,
                  title: 'Coming Soon',
                  subtitle: 'Edit feature will be available soon!',
                  icon: Icons.construction_rounded,
                  iconColor: Colors.amber,
                );
              } else if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: kAccent, size: 20),
                        const SizedBox(width: 10),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Goal Info Card ──
              _flatCard(
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: goalColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getGoalIcon(widget.goal.icon),
                        color: goalColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.goal.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.goal.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.goal.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDetailItem(
                          'Category',
                          widget.goal.category,
                          Icons.category_outlined,
                        ),
                        _buildDetailItem(
                          'Frequency',
                          widget.goal.targetFrequency,
                          Icons.repeat_rounded,
                        ),
                        _buildDetailItem(
                          'Target',
                          '${widget.goal.targetCount}x',
                          Icons.flag_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Statistics Section ──
              BlocBuilder<GoalBloc, GoalState>(
                builder: (context, state) {
                  if (state is GoalStatsLoaded &&
                      state.goalId == widget.goal.id) {
                    return _buildStatsCard(context, state.stats);
                  } else if (state is GoalError) {
                    return _flatCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 44,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Failed to load statistics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: _loadStats,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return _flatCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: kAccent),
                        const SizedBox(height: 14),
                        Text(
                          'Loading statistics...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // ── Quick Actions ──
              _flatCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.read<GoalBloc>().add(
                                  LogGoalStatus(
                                    goalId: widget.goal.id,
                                    status: 'completed',
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Mark Complete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34C759),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.read<GoalBloc>().add(
                                  LogGoalStatus(
                                    goalId: widget.goal.id,
                                    status: 'missed',
                                  ),
                                );
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Mark Missed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF3B30),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: kAccent),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Goal'),
            content: Text(
              'Are you sure you want to delete "${widget.goal.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<GoalBloc>().add(
                    DeleteGoal(goalId: widget.goal.id),
                  );
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
