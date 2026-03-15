import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../application/goal/goal_bloc.dart';
import '../../application/goal/goal_event.dart';
import '../../application/goal/goal_state.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../domain/entities/goals/goal_reminder.dart';
import '../../infrastucture/models/goals/goal.dart';

class CreateGoalScreen extends StatefulWidget {
  final Goal? goalToEdit;
  const CreateGoalScreen({Key? key, this.goalToEdit}) : super(key: key);

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late TabController _iconTabController;

  String _selectedCategory = 'Health';
  String _selectedFrequency = 'daily';
  int _targetCount = 1;
  String _selectedColor = '#4CAF50';
  String _selectedIcon = 'fitness';

  // ✅ Reminders state
  List<GoalReminder> _reminders = [];

  final List<String> _categories = [
    'Health',
    'Fitness',
    'Learning',
    'Work',
    'Personal',
    'Hobbies',
    'Social',
    'Spiritual',
    'Finance',
    'Nutrition',
    'Sleep',
    'Mindfulness',
  ];

  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];

  // ── 12 curated colors ───────────────────────────────────
  final List<Map<String, dynamic>> _colors = [
    {'name': 'Emerald', 'value': '#4CAF50'},
    {'name': 'Sky', 'value': '#2196F3'},
    {'name': 'Violet', 'value': '#9C27B0'},
    {'name': 'Amber', 'value': '#FF9800'},
    {'name': 'Rose', 'value': '#F44336'},
    {'name': 'Pink', 'value': '#E91E63'},
    {'name': 'Teal', 'value': '#009688'},
    {'name': 'Indigo', 'value': '#3F51B5'},
    {'name': 'Cyan', 'value': '#00BCD4'},
    {'name': 'Lime', 'value': '#8BC34A'},
    {'name': 'Gold', 'value': '#FFC107'},
    {'name': 'Coral', 'value': '#FF5722'},
  ];

  // ── Icons grouped by tab ────────────────────────────────
  final List<Map<String, dynamic>> _iconGroups = [
    {
      'tab': 'Health',
      'icons': [
        {'name': 'Fitness', 'value': 'fitness', 'icon': Icons.fitness_center},
        {'name': 'Run', 'value': 'run', 'icon': Icons.directions_run},
        {'name': 'Yoga', 'value': 'meditation', 'icon': Icons.self_improvement},
        {'name': 'Heart', 'value': 'heart', 'icon': Icons.favorite},
        {'name': 'Water', 'value': 'water', 'icon': Icons.local_drink},
        {'name': 'Sleep', 'value': 'sleep', 'icon': Icons.bedtime},
      ],
    },
    {
      'tab': 'Work',
      'icons': [
        {'name': 'Book', 'value': 'book', 'icon': Icons.menu_book},
        {'name': 'Study', 'value': 'study', 'icon': Icons.school},
        {'name': 'Work', 'value': 'work', 'icon': Icons.work},
        {'name': 'Code', 'value': 'code', 'icon': Icons.code},
        {'name': 'Write', 'value': 'write', 'icon': Icons.edit_note},
        {'name': 'Research', 'value': 'research', 'icon': Icons.science},
      ],
    },
    {
      'tab': 'Life',
      'icons': [
        {'name': 'Star', 'value': 'star', 'icon': Icons.star},
        {'name': 'Music', 'value': 'music', 'icon': Icons.music_note},
        {'name': 'Finance', 'value': 'finance', 'icon': Icons.savings},
        {'name': 'Travel', 'value': 'travel', 'icon': Icons.flight},
        {'name': 'Nature', 'value': 'nature', 'icon': Icons.park},
        {'name': 'Social', 'value': 'social', 'icon': Icons.people},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _iconTabController = TabController(length: _iconGroups.length, vsync: this);
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _iconTabController.dispose();
    super.dispose();
  }

  // ── Snackbar ─────────────────────────────────────────────────────────────────

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

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _handleCreateGoal() {
    if (_formKey.currentState?.validate() != true) return;
    try {
      context.read<GoalBloc>().add(
        CreateGoal(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          color: _selectedColor,
          icon: _selectedIcon,
          targetFrequency: _selectedFrequency,
          targetCount: _targetCount,
        ),
      );
    } catch (e) {
      _showClassicSnackbar(
        context,
        title: 'Error',
        subtitle: e.toString(),
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red,
      );
    }
  }

  // ── Reminders helpers ────────────────────────────────────────────────────────

  String _generateReminderId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  void _addReminder() {
    if (_reminders.length >= 5) return;
    setState(() {
      _reminders.add(
        GoalReminder(
          id: _generateReminderId(),
          time: '08:00',
          label: '',
          enabled: true,
        ),
      );
    });
  }

  void _deleteReminder(int index) => setState(() => _reminders.removeAt(index));

  void _toggleReminder(int index, bool val) {
    setState(() {
      final r = _reminders[index];
      _reminders[index] = GoalReminder(
        id: r.id,
        time: r.time,
        label: r.label,
        enabled: val,
      );
    });
  }

  Future<void> _pickReminderTime(int index) async {
    final r = _reminders[index];
    final parts = r.time.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';

    setState(() {
      _reminders[index] = GoalReminder(
        id: r.id,
        time: timeStr,
        label: r.label,
        enabled: r.enabled,
      );
    });
  }

  void _updateReminderLabel(int index, String val) {
    // No setState needed here — doesn't affect layout, called from onChanged
    final r = _reminders[index];
    _reminders[index] = GoalReminder(
      id: r.id,
      time: r.time,
      label: val,
      enabled: r.enabled,
    );
  }

  // ── Misc helpers ─────────────────────────────────────────────────────────────

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.deepPurple;
    }
  }

  IconData _getSelectedIconData() {
    for (final group in _iconGroups) {
      for (final icon in group['icons'] as List) {
        if (icon['value'] == _selectedIcon) return icon['icon'] as IconData;
      }
    }
    return Icons.star;
  }

  // ── Error / Fallback screen ──────────────────────────────────────────────────

  Widget _buildWithGoalBloc(BuildContext context) {
    try {
      context.read<GoalBloc>();
      return _buildScreen(context);
    } catch (_) {
      try {
        final goalBloc = GetIt.instance<GoalBloc>();
        return BlocProvider<GoalBloc>.value(
          value: goalBloc,
          child: _buildScreen(context),
        );
      } catch (_) {
        return _buildErrorScreen();
      }
    }
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Goal')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Goal service is not available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ── Common widget helpers ────────────────────────────────────────────────────

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black38),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _classicCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // ── Main screen ──────────────────────────────────────────────────────────────

  Widget _buildScreen(BuildContext context) {
    final accent = _getColorFromHex(_selectedColor);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'New Goal',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black.withOpacity(0.07)),
        ),
      ),
      body: BlocConsumer<GoalBloc, GoalState>(
        listener: (context, state) {
          // ── Goal created ────────────────────────────────
          if (state is GoalCreated) {
            // Pop and show snackbar immediately regardless of reminders
            Navigator.pop(context);
            final active = _reminders.where((r) => r.enabled).length;
            _showClassicSnackbar(
              context,
              title: 'Goal Created!',
              subtitle:
                  active > 0
                      ? 'Added with $active active reminder${active > 1 ? 's' : ''}'
                      : 'Your new habit has been added',
              icon: Icons.check_rounded,
              iconColor: Colors.green,
            );

            // Fire reminders update in background — don't wait for it
            if (_reminders.isNotEmpty) {
              context.read<GoalBloc>().add(
                UpdateGoalReminders(
                  goalId: state.goal.id,
                  reminders: _reminders,
                ),
              );
            }
          } else if (state is GoalError) {
            _showClassicSnackbar(
              context,
              title: 'Something went wrong',
              subtitle: state.message,
              icon: Icons.error_outline_rounded,
              iconColor: Colors.red,
            );
          } else if (state is GoalValidationError) {
            final err = state.fieldErrors['general'];
            if (err != null) {
              _showClassicSnackbar(
                context,
                title: 'Validation Error',
                subtitle: err,
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orange,
              );
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is GoalActionLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── DETAILS ────────────────────────────
                    _classicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('GOAL DETAILS', Icons.flag_outlined),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _titleController,
                            labelText: 'Goal Title',
                            hintText: 'e.g., Exercise daily',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty)
                                return 'Please enter a goal title';
                              if (value.trim().length < 3)
                                return 'Title must be at least 3 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _descriptionController,
                            labelText: 'Description (Optional)',
                            hintText: 'Add more details...',
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── CATEGORY ───────────────────────────
                    _classicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('CATEGORY', Icons.category_outlined),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final cat = _categories[i];
                                final isSelected = _selectedCategory == cat;
                                return GestureDetector(
                                  onTap:
                                      () => setState(
                                        () => _selectedCategory = cat,
                                      ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? accent
                                              : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? accent
                                                : Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black54,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── FREQUENCY ──────────────────────────
                    _classicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('FREQUENCY', Icons.repeat_outlined),
                          const SizedBox(height: 12),
                          Row(
                            children:
                                _frequencies.map((freq) {
                                  final isSelected = _selectedFrequency == freq;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => setState(
                                            () => _selectedFrequency = freq,
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 160,
                                        ),
                                        margin: EdgeInsets.only(
                                          right:
                                              freq != _frequencies.last ? 8 : 0,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? accent
                                                  : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? accent
                                                    : Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Text(
                                          freq.capitalize(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Text(
                                'Times per period',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              _stepperBtn(Icons.remove, () {
                                if (_targetCount > 1)
                                  setState(() => _targetCount--);
                              }, accent),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '$_targetCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              _stepperBtn(Icons.add, () {
                                if (_targetCount < 20)
                                  setState(() => _targetCount++);
                              }, accent),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── REMINDERS ──────────────────────────
                    _classicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel(
                            'REMINDERS',
                            Icons.notifications_outlined,
                          ),
                          const SizedBox(height: 12),

                          // Existing reminders list
                          ..._reminders.asMap().entries.map((entry) {
                            final i = entry.key;
                            final r = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        r.enabled
                                            ? accent.withOpacity(0.25)
                                            : Colors.grey[200]!,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    // Toggle
                                    Transform.scale(
                                      scale: 0.85,
                                      child: Switch(
                                        value: r.enabled,
                                        activeColor: accent,
                                        onChanged:
                                            (val) => _toggleReminder(i, val),
                                      ),
                                    ),

                                    // Time chip
                                    GestureDetector(
                                      onTap: () => _pickReminderTime(i),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 12,
                                              color: accent,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              r.time,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: accent,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Label field
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          hintText: 'Label (optional)',
                                          border: InputBorder.none,
                                          isDense: true,
                                          hintStyle: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black38,
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        onChanged:
                                            (val) =>
                                                _updateReminderLabel(i, val),
                                      ),
                                    ),

                                    // Delete
                                    GestureDetector(
                                      onTap: () => _deleteReminder(i),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // Empty hint
                          if (_reminders.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'No reminders set',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),

                          // Add reminder button (max 5)
                          if (_reminders.length < 5)
                            GestureDetector(
                              onTap: _addReminder,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: accent.withOpacity(0.35),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: accent.withOpacity(0.04),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: 16, color: accent),
                                    const SizedBox(width: 6),
                                    Text(
                                      _reminders.isEmpty
                                          ? 'Add Reminder'
                                          : 'Add Another Reminder',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Limit reached hint
                          if (_reminders.length >= 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Maximum 5 reminders per goal',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── APPEARANCE ─────────────────────────
                    _classicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('APPEARANCE', Icons.palette_outlined),
                          const SizedBox(height: 16),

                          // Color — horizontal scroll
                          const Text(
                            'Color',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _colors.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final c = _colors[i];
                                final isSelected = _selectedColor == c['value'];
                                final col = _getColorFromHex(
                                  c['value'] as String,
                                );
                                return GestureDetector(
                                  onTap:
                                      () => setState(
                                        () =>
                                            _selectedColor =
                                                c['value'] as String,
                                      ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: col,
                                      shape: BoxShape.circle,
                                      border:
                                          isSelected
                                              ? Border.all(
                                                color: Colors.black87,
                                                width: 2.5,
                                              )
                                              : Border.all(
                                                color: Colors.transparent,
                                                width: 2,
                                              ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: col.withOpacity(0.45),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                              : [],
                                    ),
                                    child:
                                        isSelected
                                            ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                            : null,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Icon — tabbed 3 groups × 6
                          const Text(
                            'Icon',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Tab bar
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TabBar(
                              controller: _iconTabController,
                              indicator: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.black45,
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              dividerColor: Colors.transparent,
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs:
                                  _iconGroups
                                      .map((g) => Tab(text: g['tab'] as String))
                                      .toList(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Icon grid — fixed height
                          SizedBox(
                            height: 120,
                            child: TabBarView(
                              controller: _iconTabController,
                              children:
                                  _iconGroups.map((group) {
                                    final icons = group['icons'] as List;
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children:
                                          icons.map((iconData) {
                                            final isSelected =
                                                _selectedIcon ==
                                                iconData['value'];
                                            return GestureDetector(
                                              onTap:
                                                  () => setState(
                                                    () =>
                                                        _selectedIcon =
                                                            iconData['value']
                                                                as String,
                                                  ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 150,
                                                    ),
                                                    width: 52,
                                                    height: 52,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isSelected
                                                              ? accent
                                                                  .withOpacity(
                                                                    0.12,
                                                                  )
                                                              : Colors
                                                                  .grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            13,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            isSelected
                                                                ? accent
                                                                : Colors
                                                                    .grey[300]!,
                                                        width:
                                                            isSelected ? 2 : 1,
                                                      ),
                                                      boxShadow:
                                                          isSelected
                                                              ? [
                                                                BoxShadow(
                                                                  color: accent
                                                                      .withOpacity(
                                                                        0.18,
                                                                      ),
                                                                  blurRadius: 8,
                                                                ),
                                                              ]
                                                              : [],
                                                    ),
                                                    child: Icon(
                                                      iconData['icon']
                                                          as IconData,
                                                      color:
                                                          isSelected
                                                              ? accent
                                                              : Colors
                                                                  .grey[400],
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    iconData['name'] as String,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          isSelected
                                                              ? accent
                                                              : Colors.black38,
                                                      fontWeight:
                                                          isSelected
                                                              ? FontWeight.w700
                                                              : FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                    );
                                  }).toList(),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Live preview
                          const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accent.withOpacity(0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getSelectedIconData(),
                                    color: accent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _titleController.text.isEmpty
                                            ? 'Goal'
                                            : _titleController.text,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            '$_selectedCategory · ${_selectedFrequency.capitalize()}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          // ✅ Show reminder count in preview
                                          if (_reminders.any(
                                            (r) => r.enabled,
                                          )) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.notifications_active,
                                              size: 11,
                                              color: accent,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${_reminders.where((r) => r.enabled).length}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: accent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── CREATE BUTTON ──────────────────────
                    CustomButton(
                      text: 'Create Goal',
                      onPressed: isLoading ? null : _handleCreateGoal,
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildWithGoalBloc(context);
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
